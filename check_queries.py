import os
from enum import Enum
import re
import argparse
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.exc import OperationalError, ProgrammingError
from sqlalchemy.engine import Engine
import pandas as pd
from pandas.errors import DatabaseError as PandasDatabaseError
from rich.progress import track

DB_CONNECTOR = "mysql+pymysql://user:bootcamp@172.30.1.156:3306"

def error_message(line_num:int|None, exercise_num:int|None, msg:str) -> str:
    if line_num is not None:
        return f"❌ [Error inesperado en la línea {line_num}] {msg}\n"
    if exercise_num is not None:
        return f"❌ [Error inesperado en el ejercicio {exercise_num}] {msg}\n"
    return f"❌ [Error inesperado] {msg}\n"

def get_queries(file)->tuple[dict[int, tuple[str, list[str]]], int]:
    """
        Gets queries from a file. Multiple solutions can be made for the same exercise. It is expected
        that each solution for a exercise is preceeded by a commnent that starts with "-- {exercise_num}.".
        
        Args:
            file: the file containing the queries.

        Returns:
            dict[exercise_num, tuple[database, list_of_queries]]
                - exercise_num: number of exercise.
                - database: a str representing on which database these queries must be run on
                - list_of_queries: a list[str] containing all the user's solutions for this exercise
        """
    def add_query(idx:int, exercise_num:int, database:str, query:str):
        if exercise_num in queries:
            if database != queries[exercise_num][0]:
                raise RuntimeError(error_message(idx, None, "\n\tPuede que estés usando diferentes bases de datos para ejecutar las soluciones del ejercicio {exercise_num}"))
        
            queries[exercise_num][1].append(query)
            return
        
        queries[exercise_num] = (database, [query])

    exercise_statement_pattern = r"^--\s*(\d+)\..*"     # Pattern for identifying problem statements
    use_database_pattern = r"(?i)^\s*use\s+([\w\d_]+);" # Pattern for identifying 'USE database1;' sql statements
    query_pattern = r"(?i)^\s*(?:select|with)\b"        # Pattern for catching queries (solutions to exercises)
    end_of_query_pattern = r"^((?!--).)*;"              # Pattern for checking if query has ended
    ignore_pattern = r"(?i)^-- ignore$"                 # Pattern for ignoring

    current_db, current_exercise_num = None, None

    max_exercise_num = 0

    queries:dict[int, tuple[str, list[str]]] = {}

    idx, lines = 0, file.readlines()
    while idx < len(lines):
        line = lines[idx]

        match = re.match(use_database_pattern, line)
        if match:
            current_db = match.group(1)
            idx += 1
            continue

        match = re.match(exercise_statement_pattern, line)
        if match:
            current_exercise_num = int(match.group(1))
            max_exercise_num = max(max_exercise_num, current_exercise_num)
            idx += 1
            continue

        match = re.match(ignore_pattern, line)
        if match:
            current_exercise_num = None
            idx += 1
            continue

        match = re.match(query_pattern, line)
        if match:
            query_start_idx = idx
            while not re.match(end_of_query_pattern, line) and not re.match(exercise_statement_pattern, line):
                idx += 1
                line = lines[idx]
                if re.match(exercise_statement_pattern, line):
                    idx -= 1
                    continue
            query = ''.join(lines[query_start_idx:idx + 1])

            if current_db is not None and current_exercise_num is not None:
                add_query(query_start_idx, current_exercise_num, current_db, query)
            if current_db is None and current_exercise_num is not None:
                raise RuntimeError(error_message(query_start_idx, None, f"No has elegido una base de datos para la cual ejecutar el ejercicio {current_exercise_num}"))

        idx += 1

    return queries, max_exercise_num

class QueryResult(str, Enum):
    ORDER_ERROR = 1
    CONTENT_ERROR = 2
    SYNTAX_ERROR = 3
    QUERY_RAN_ON_WONG_DB = 4
    CORRECT = 5

class ConnectionManager():
    def __init__(self, databases:set[str]):
        self.connections:dict[str, Engine] = {}
        for database in databases:
            try:
                con = create_engine(DB_CONNECTOR + f"/{database}")
                with con.connect() as connection:
                    connection.execute(text("SELECT 1")) # Verify connection

                self.connections[database] = con
            except OperationalError:
                raise RuntimeError(error_message(None, None, f"No se pudo encontrar o conectar a la base de datos: {database}. Asegúrate que tienes la VPN activada."))

    def get_connection(self, database:str) -> Engine:
        return self.connections[database]

class SolutionChecker():
    def __init__(self, con_manager:ConnectionManager, boletin:int, max_exercise_num:int):
        base_view_name = "solucion_ejercicio_" if boletin == 1 else "solucion_ejercicio_ventana_"
        db_views = {db_name : inspect(db).get_view_names() for db_name, db in con_manager.connections.items()}

        self.solutions:dict[int, str] = {}
        for i in range(1, max_exercise_num + 1):
            view = base_view_name + str(i)
            for db_name, views in db_views.items():
                if view in views:
                    self.solutions[i] = db_name
                    break

    def check_solution(self, exercise_num:int) -> str | None:
        return self.solutions.get(exercise_num, None)

def check_queries(queries:dict[int, tuple[str, list[str]]], max_exercise_num:int, boletin:int)->dict[int, tuple[bool, list[tuple[str, QueryResult]]]]:
    """
        Runs provided queries and verifies they are correct comparing ther content and order with the solution

        Args:
            queries: the same structure is expected as the return type of 'get_queries' function.

        Returns:
            dict[exercise_num, tuple[has_solution, query_results]]:
                exercise_num: number of exercise
                has_solution: boolean indicating if exercise has a solution available
                query_results: list of tuple[str, QueryResult], str is the query.
    """
    def check_content(user_result:pd.DataFrame, expected_result:pd.DataFrame) -> bool:
        if len(user_result) != len(expected_result):
            return False
        if user_result.shape[1] != expected_result.shape[1]:
            return False

        user_result = user_result.copy()
        expected_result = expected_result.copy()

        # Normalize column names to positional indices to avoid any naming mismatches
        user_result.columns = list(range(user_result.shape[1]))
        expected_result.columns = list(range(expected_result.shape[1]))

        user_sorted = user_result.sort_values(by=list(user_result.columns)).reset_index(drop=True)
        expected_sorted = expected_result.sort_values(by=list(expected_result.columns)).reset_index(drop=True)

        return user_sorted.equals(expected_sorted)

    def check_exercise(db:Engine, sol_checker:SolutionChecker, exercise_num:int, queries:list[str], boletin:int)->tuple[bool, list[tuple[str, QueryResult]]]:
        view = f"solucion_ejercicio_{exercise_num}" if boletin == 1 else f"solucion_ejercicio_ventana_{exercise_num}"
        sol_db_name = sol_checker.check_solution(exercise_num)
        if sol_db_name is None:
            return False, []
        
        if sol_db_name != db.url.database:
            return True, [(q, QueryResult.QUERY_RAN_ON_WONG_DB)  for q in queries]

        correct_query = f"select * from {view}"
        expected_result = pd.read_sql(correct_query, db)
        
        results = []
        for q in queries:
            try:
                user_result = pd.read_sql(text(q), db)
                
                if not check_content(user_result, expected_result):
                    results.append((q, QueryResult.CONTENT_ERROR))
                    continue

                # Some exercises are supposed to be ordered, others aren't.
                # if not check_order(user_result, expected_result):
                #     results.append((q, QueryResult.ORDER_ERROR))
                #     continue
                
                results.append((q, QueryResult.CORRECT))
            except (
                PandasDatabaseError,
                ProgrammingError,
                OperationalError
            ) as e:
                results.append((q, QueryResult.SYNTAX_ERROR))

        return True, results

    con_manager = ConnectionManager(set(q[0] for q in queries.values()))
    solution_checker = SolutionChecker(con_manager, boletin, max_exercise_num)

    results = {}
    for key, (database, qs) in track(queries.items(), description="Corrigiendo ejercicios: "):
        if key not in results:
            results[key] = check_exercise(con_manager.get_connection(database), solution_checker, key, qs, boletin)
        else:
            if results[key][0]:
                results[key][1] += check_exercise(con_manager.get_connection(database), solution_checker, key, qs, boletin)[1]

    for i in range(1, max_exercise_num + 1):
        if i not in results:
            if solution_checker.check_solution(i) is not None:
                results[i] = (True, [])
            else:
                results[i] = (False, [])

    return results

def print_results(results:dict[int, tuple[bool, list[tuple[str, QueryResult]]]], verbose:bool):
    print("\n")
    if verbose:
        print("Queries ran:\n")
        all_queries = []
        for v in results.values():
            all_queries += [v[0] for v in v[1]]
        print('\n'.join(all_queries))
        print("\n")
    
    no_solution = []
    no_queries_run = []
    exercises_with_errors = []
    wrong_db_exercises = set()
    total_queries = 0
    correct_queries = 0
    correct_exercises = 0

    for exercise_num, (has_solution, query_results) in sorted(results.items()):
        if not has_solution:
            no_solution.append(exercise_num)
            continue

        if not query_results:
            no_queries_run.append(exercise_num)
            continue

        total_queries += len(query_results)
        exercise_correct = True

        for query, result in query_results:
            if result == QueryResult.CORRECT:
                correct_queries += 1
            else:
                exercise_correct = False
                exercises_with_errors.append((exercise_num, query, result))

                if result == QueryResult.QUERY_RAN_ON_WONG_DB:
                    wrong_db_exercises.add(exercise_num)

        if exercise_correct:
            correct_exercises += 1

    # Print errors
    if exercises_with_errors:
        print("─" * 60)
        print("⛔  Exercises with errors:\n")
        current_exercise = None
        for exercise_num, query, result in exercises_with_errors:
            if exercise_num != current_exercise:
                print(f"  📝 Exercise {exercise_num}:")
                current_exercise = exercise_num
            if result == QueryResult.CONTENT_ERROR:
                print(f"    🔴 Content error:\n{query}")
            elif result == QueryResult.ORDER_ERROR:
                print(f"    🟡 Order error:\n{query}")
            elif result == QueryResult.SYNTAX_ERROR:
                print(f"    🟠 Syntax error:\n{query}")
            elif result == QueryResult.QUERY_RAN_ON_WONG_DB:
                print(f"    🛑 Query being ran on wrong database:\n{query}")

    # Print summary
    total_exercises = len(results)
    exercises_with_solution = total_exercises - len(no_solution)
    exercises_attempted = exercises_with_solution - len(no_queries_run)
    print("─" * 60)
    print("📊  Summary:")
    print(f"  {'✅' if correct_exercises == exercises_attempted else '❌'}  Correct exercises:  {correct_exercises} / {exercises_attempted}")
    print(f"  {'✅' if correct_queries == total_queries else '❌'}  Correct queries:    {correct_queries} / {total_queries}")
    if no_queries_run:
        print(f"  🚫  { 'Exercises with a solution but no queries submitted:':<55} {len(no_queries_run)} exercise(s) → {', '.join(map(str, no_queries_run))}")
    if no_solution:
        print(f"  ⚠️   { 'Exercises with no solution:':<55} {len(no_solution)} exercise(s) → {', '.join(map(str, no_solution))}")
    if wrong_db_exercises:
        print(f"  ⛔   { 'Exercises ran on wrong db:':<55} {len(wrong_db_exercises)} exercise(s) → {', '.join(map(str, wrong_db_exercises))}")
    if correct_queries == total_queries and correct_exercises == exercises_attempted and not no_queries_run:
        print("\n")
        print("🟢 🥳🎉Enhorabuena!🎉🥳 🟢")
    print()
    print("─" * 60)

def parse_args():
    parser = argparse.ArgumentParser(description="Un script para verifcar que tus queries de SQL son correctas 😊")
    parser.add_argument("path", type=str, help="El path al archivo que contiene tus queries")
    parser.add_argument("boletin", type=int, help="El boletin para el cuál vas a subir las solciones (ha de ser 1 o 3 ya que los boletines 2 y 4 no tiene los ejercicios resueltos)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Muestra resultados en mayor detalle")
    args = parser.parse_args()

    if not os.path.exists(args.path):
        print(f"❌ No se ha encontrado el archivo '{args.path}'")
        return None
    
    if args.boletin != 1 and args.boletin != 3:
        print(f"❌ Solo los boletines 1 y 3 tienen los ejercicios resueltos, por lo tanto has de proporcionar el valor '1' o '3', no '{args.boletin}'")
        return None
    
    return args

def main():
    args = parse_args()
    if args is None:
        return

    print("Obteniendo queries...")
    with open(args.path, 'r', encoding='utf-8') as file:
        queries, max_exercise_num = get_queries(file)

    results = check_queries(queries, max_exercise_num, args.boletin)

    assert all(len(queries[q][1]) == len(results[q][1]) for q in queries.keys() if results[q][0]), f"Number of queries for which there is a solution and number of queries solved doesn't match."

    print_results(results, args.verbose)

if __name__ == "__main__":
    main()