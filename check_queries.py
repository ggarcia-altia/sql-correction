import os
from enum import Enum
import re
import argparse
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.engine import Engine
import pandas as pd
import pymysql
from rich.progress import track

"""
    ⚠️ Leer antes de usar!

    Este script corrige tus ejercicios de SQL de los boletines 1 y 3 del datacamp de Altia. Hace falta
    estar conectado a la VPN para que este script funciona.
    
    Para que estos ejercicios se corrijan bien ten en cuenta que:

    - Puedes escribir diferentes soluciones para el mismo ejercicio y todas se corregirán.

    - Las queries para resolver determinado ejercicio han de estar debajo del enunciado del ejercico. Si una query
    que resuelve el ejercicio X tiene como enunciado más cercano encima de ella el enunciado Y, se interpretará que
    es una solución del ejercicio Y. Se interpreta que se está resolviendo un enunciado cuando se encuentra una línea
    con el siguiente formato "-- X.*", donde X es el número del ejercicio (el asterisco * indica que puede haber más
    carácteres después de esa cadena, serán ignorados). Es decir, se entiende que las queries leídas pertenecen al
    ejercicio para el cual apareció la última línea de ese formato.

    - Puedes añadir tus propios comentarios, tus queries pueden ocupar múltiples líneas y puedes dejar líneas en blanco.

    - Si quieres que unas queries se ignoren escribe "-- ignore" y todas las queries que estén entre este comentario y
    el enunciado del siguiente ejercicio serán ingoradas.

    - Ten en cuenta que tus soluciones se ejecutarán en orden cambiando de base de datos cuando aparece una sentencia
    USE de sql. Si el ejercicio X se ejecuta en la base de datos A y el ejercicio X+1 se ejecuta en la base de datos B,
    tendrás que incluir una sentencia "USE ...;" justo antes del ejericico X+1 para que se cambie de base de datos y se
    puedan ejecutar las soluciones del ejercicio X+1.

    - No escribas varias queries en la misma línea, esto probablemente cause que ignoren todoas las queries de esa línea
    excepto la última.

    💻 Para ejecutar este script en windos usando VS Code:
        1. Instala python
        2. Pulsando CTRL + shift + p, pulsa en la opción "Python: Create Environment", elige venv
        y selecciona un interpretador.
        3. Abre la terminal de VS Code, deberías ver ".venv".
        4. Instala dependencias con "pip install sqlalchemy pandas pymysql rich"
        5. Ejecuta el archivo:
            python check_queries.py tu_ruta_a_tu_boletin1.sql 1

    ❗ Problems
        - Queries like this don't work:
            SELECT sal INTO @EmployeeSal 
            FROM emp 
            WHERE empno = 7934;
            SELECT * FROM emp WHERE sal > @EmployeeSal ORDER BY sal;
"""

DB_CONNECTOR = "mysql+pymysql://user:bootcamp@172.30.1.156:3306"

def error_message(line_num:int|None, exercise_num:int|None, msg:str) -> str:
    if line_num is not None:
        return f"❌ [Error inesperado en la línea {line_num}] {msg}\n"
    if exercise_num is not None:
        return f"❌ [Error inesperado en el ejercicio {exercise_num}] {msg}\n"
    return f"❌ [Error inesperado] {msg}\n"

def get_queries(file)->dict[int, tuple[str, list[str]]]:
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
    use_database_pattern = r"(?i)^\s*use\s+([\w\d_]+);"     # Pattern for identifying 'USE database1;' sql statements
    query_pattern = r"(?i)^\s*(?:select|with)\b"        # Pattern for catching queries (solutions to exercises)
    ignore_pattern = r"(?i)^-- ignore$"

    current_db, current_exercise_num = None, None

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
            while ';' not in line:
                idx += 1
                line = lines[idx]
            query = ''.join(lines[query_start_idx:idx + 1])

            if current_db is not None and current_exercise_num is not None:
                add_query(query_start_idx, current_exercise_num, current_db, query)
            if current_db is None and current_exercise_num is not None:
                raise RuntimeError(error_message(query_start_idx, None, f"No has elegido una base de datos para la cual ejecutar el ejercicio {current_exercise_num}"))

        idx += 1

    return queries        

class QueryResult(Enum):
    ORDER_ERROR = 1
    CONTENT_ERROR = 2
    SYNTAX_ERROR = 3
    CORRECT = 4

class ConnectionManager():
    def __init__(self):
        self.connections = {}

    def get_connection(self, database:str) -> Engine:
        if database not in self.connections:
            try:
                con = create_engine(DB_CONNECTOR + f"/{database}")
                with con.connect() as connection:
                    connection.execute(text("SELECT 1")) # Verify connection

                self.connections[database] = con
            except OperationalError:
                raise RuntimeError(error_message(None, None, f"No se pudo encontrar o conectar a la base de datos: {database}. Asegúrate que tienes la VPN activada."))
        
        return self.connections[database]
    
def check_queries(queries:dict[int, tuple[str, list[str]]], boletin:int)->dict[int, tuple[bool, list[tuple[str, QueryResult]]]]:
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
    
        user_sorted = user_result.sort_values(by=list(user_result.columns)).reset_index(drop=True)
        expected_sorted = expected_result.sort_values(by=list(expected_result.columns)).reset_index(drop=True)
        
        return user_sorted.equals(expected_sorted)

    def check_order(user_result:pd.DataFrame, expected_result:pd.DataFrame) -> bool:
        return user_result.reset_index(drop=True).equals(expected_result.reset_index(drop=True))

    def check_view_exists(db:Engine, view_name: str) -> bool:
        inspector = inspect(db)
        return view_name in inspector.get_view_names()

    def check_exercise(db:Engine, exercise_num:int, queries:list[str], boletin:int)->tuple[bool, list[tuple[str, QueryResult]]]:
        view = f"solucion_ejercicio_{exercise_num}" if boletin == 1 else f"solucion_ejercicio_ventana_{exercise_num}"
        if not check_view_exists(db, view):
            return False, []

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
            except pymysql.err.ProgrammingError as e:
                results.append((q, QueryResult.SYNTAX_ERROR))

        return True, results

    con_manager = ConnectionManager()

    results = {}
    for key, (database, qs) in track(queries.items(), description="Ejercicios corregidos..."):
        if key not in results:
            results[key] = check_exercise(con_manager.get_connection(database), key, qs, boletin)
        else:
            if results[key][0]:
                results[key][1] += check_exercise(con_manager.get_connection(database), key, qs, boletin)[1]

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
                print(f"    🔴 Content error:  {query}")
            elif result == QueryResult.ORDER_ERROR:
                print(f"    🟡 Order error:    {query}")
            elif result == QueryResult.SYNTAX_ERROR:
                print(f"    🟠 Syntax error:   {query}")

    # Print exercises with solution but no queries run
    if no_queries_run:
        print("─" * 60)
        print(f"🚫  Exercises with a solution but no queries submitted: {', '.join(map(str, no_queries_run))}")

    # Print no solution
    if no_solution:
        print("─" * 60)
        print(f"⚠️  Exercises with no solution: {', '.join(map(str, no_solution))}")

    # Print summary
    total_exercises = len(results)
    exercises_with_solution = total_exercises - len(no_solution)
    exercises_attempted = exercises_with_solution - len(no_queries_run)
    print("─" * 60)
    print("📊  Summary:")
    print(f"  {'✅' if correct_exercises == exercises_attempted else '❌'}  Correct exercises:  {correct_exercises} / {exercises_attempted}")
    print(f"  {'✅' if correct_queries == total_queries else '❌'}  Correct queries:    {correct_queries} / {total_queries}")
    if no_queries_run:
        print(f"  🚫  No queries run:     {len(no_queries_run)} exercise(s) → {', '.join(map(str, no_queries_run))}")
    if no_solution:
        print(f"  ⚠️   No solution:        {len(no_solution)} exercise(s) → {', '.join(map(str, no_solution))}")
    if correct_queries == total_queries and correct_exercises == exercises_attempted and not no_queries_run:
        print("🟢 🥳🎉Enhorabuena!🎉🥳 🟢")
    print()
    print("─" * 60)

def main():
    parser = argparse.ArgumentParser(description="Un script para verifcar que tus queries de SQL son correctas 😊")
    parser.add_argument("path", type=str, help="El path al archivo que contiene tus queries")
    parser.add_argument("boletin", type=int, help="El boletin para el cuál vas a subir las solciones (ha de ser 1 o 3 ya que los boletines 2 y 4 no tiene los ejercicios resueltos)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Muestra resultados en mayor detalle")
    args = parser.parse_args()

    if not os.path.exists(args.path):
        print(f"❌ No se ha encontrado el archivo '{args.path}'")
        return
    
    if args.boletin != 1 and args.boletin != 3:
        print(f"❌ Solo los boletines 1 y 3 tienen los ejercicios resueltos, por lo tanto has de proporcionar el valor '1' o '3', no '{args.boletin}'")
        return
    
    print("Obteniendo queries...")
    with open(args.path, 'r', encoding='utf-8') as file:
        queries = get_queries(file)

    print("Ejecutando y comprobando que las queries son correctas, un segundo...")
    results = check_queries(queries, args.boletin)

    num_queries_have_solution = sum(len(queries[key][1]) for key in results)
    num_queries_solved = sum(len(v[1]) for v in results.values())
    assert num_queries_have_solution == num_queries_solved, f"Number of queries for which there is a solution and number of queries solved doesn't match: {num_queries_solved} {num_queries_have_solution}."

    print_results(results, args.verbose)

if __name__ == "__main__":
    main()