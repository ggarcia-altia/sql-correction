-- Cuando se necesite usar otra base de datos en un ejercicio, se indicará al principio del mismo.
-- Ejemplo: (DB jardineria) Muestra los nombres ...
USE basic_employees;

-- 1. Halla los empleados que tienen una comisión superior a la mitad de su salario.
-- This could be optimized with a bit shift (?)
SELECT * FROM emp e WHERE e.sal < e.comm * 2;
SELECT * FROM solucion_ejercicio_1;

-- 2. Halla los empleados que no tienen comisión, o que la tengan menor o igual que el 25% de su salario.
-- This could be optimized with bit shifts (?)
SELECT * FROM emp e WHERE e.comm IS NULL OR e.comm * 4 <= e.sal;
SELECT * FROM solucion_ejercicio_2;

-- 3. Obtén los empleados que no son supervisados por ningún otro.
SELECT * FROM emp e WHERE e.mgr IS NULL;
SELECT * FROM solucion_ejercicio_3;

-- 4. Para los empleados que tengan comisión, Obtén sus nombres y el cociente entre su salario y su comisión (excepto 
-- cuando la comisión sea cero), ordenando el resultado por nombre.
SELECT ename, sal/comm FROM emp WHERE comm > 0 ORDER BY ename;
SELECT * FROM solucion_ejercicio_4;

-- 5. Para los empleados que tengan como jefe a un empleado con código mayor que el suyo, Obtén los que reciben de 
-- salario más de 1000 y menos de 2000, o que están en el departamento 30.
-- How does a BETWEEN work internally?
SELECT * FROM emp WHERE mgr > empno AND (sal BETWEEN 1000+1 AND 2000-1 OR deptno = 30);
SELECT * FROM solucion_ejercicio_5;

-- 6. Obtén el nombre, salario, comisión y salario total (salario + comisión, si tiene comisión) de los empleados con 
-- salario total superior a 2300.
SELECT ename, sal, comm, sal + COALESCE(comm,0) FROM emp WHERE sal + COALESCE(comm, 0) > 2300;
SELECT * FROM solucion_ejercicio_6;

-- 7. Obtén los puestos de trabajo que hay en cada departamento, de forma que no se repitan filas.
SELECT DISTINCT deptno, job FROM emp;
SELECT * FROM solucion_ejercicio_7;

-- 8. Obtén el salario más alto de la empresa, el total destinado a comisiones y el número de empleados.
SELECT MAX(sal), SUM(comm), COUNT(empno) FROM emp;
SELECT * FROM solucion_ejercicio_8;

-- 9. Halla el nombre el último empleado por orden alfabético.
SELECT ename FROM emp ORDER BY ename DESC LIMIT 1;
SELECT * FROM solucion_ejercicio_9;

-- 10. Halla el salario más alto, el más bajo, y la diferencia entre ellos.
SELECT MAX(sal), MIN(sal), MAX(sal) - MIN(sal) FROM emp;
SELECT * FROM solucion_ejercicio_10;

-- 11. ¿Cuántos empleos diferentes, cuántos empleados, y cuántos salarios diferentes encontramos en el departamento 30, 
-- y a cuánto asciende la suma de salarios de dicho departamento?
SELECT COUNT(DISTINCT job), COUNT(empno), COUNT(DISTINCT sal), SUM(sal) FROM emp WHERE deptno = 30;
SELECT * FROM solucion_ejercicio_11;

-- 12. ¿Cuántos empleados tiene el departamento 20?
SELECT COUNT(empno) FROM emp WHERE deptno = 20;
SELECT * FROM solucion_ejercicio_12;

-- 13. ¿Cuántos empleados tienen comisión?
-- Can I do this? SELECT COUNT(empno) FROM emp WHERE comm;? No, NULL is not considered False
SELECT COUNT(empno) FROM emp WHERE comm IS NOT NULL;
SELECT * FROM solucion_ejercicio_13;

-- 14. ¿Qué empleos distintos encontramos en la empresa, y cuántos empleados desempeñan cada uno de ellos?
SELECT job, COUNT(empno) FROM emp GROUP BY job;
SELECT * FROM solucion_ejercicio_14;

-- 15. Halla la suma de salarios de cada departamento, junto con el código del departamento.
SELECT deptno, SUM(sal) FROM emp GROUP BY deptno;
SELECT * FROM solucion_ejercicio_15;

-- 16. Para cada departamento muestra cuántos proyectos controla, junto con el código del departamento.
SELECT deptno, COUNT(prono) FROM pro GROUP BY deptno;
SELECT * FROM solucion_ejercicio_16;

-- 17. Muestra los proyectos en los que trabaja al menos tres empleados y cuántas horas trabajan en dichos proyectos.
SELECT prono, SUM(hours) FROM emppro GROUP BY prono HAVING COUNT(empno) > 2;
-- Comentario mio :)
SELECT prono, empno, hours
FROM (
    SELECT 
        prono, 
        empno, 
        hours,
        COUNT(empno) OVER(PARTITION BY prono) as employee_count
    FROM emppro
) AS subquery
WHERE employee_count > 2;
SELECT * FROM solucion_ejercicio_17;

-- 18. Para cada departamento muestra cuántos proyectos controla en cada ciudad.
SELECT deptno, loc, COUNT(prono) FROM pro GROUP BY deptno, loc;
SELECT * FROM solucion_ejercicio_18;

-- 19. Para cada departamento muestra cuántos empleados tiene que ganen más de 1500. Considera el total como la suma de
-- salario y comisión. Maneja correctamente los nulos.
SELECT deptno, COUNT(empno)
FROM emp
WHERE sal + COALESCE(comm, 0) > 1500
GROUP BY deptno;
SELECT * FROM solucion_ejercicio_19;

-- 20. Muestra los departamentos que tienen un salario mínimo mayor o igual a 1000. Muestra su código y cuántos 
-- empleados tiene.
SELECT deptno, COUNT(empno) FROM emp GROUP BY deptno HAVING MIN(sal) >= 1000;
SELECT * FROM solucion_ejercicio_20;

-- 21. Muestra los departamentos y los trabajos donde hay por lo menos dos trabajadores con ese puesto de trabajo.
-- SELECT deptno, job FROM emp GROUP BY deptno, job HAVING COUNT(job) > 1--;
--SELECT * FROM solucion_ejercicio_21;

-- 22. Halla los datos de los empleados cuyo salario es mayor que el del empleado de código 7934, ordenando por el 
-- salario.
--SELECT sal INTO @EmployeeSal 
--FROM emp 
--WHERE empno = 7934;
--SELECT * FROM emp WHERE sal > @EmployeeSal ORDER BY sal;

SELECT * FROM emp 
WHERE sal > (SELECT sal FROM emp WHERE empno = 7934)
ORDER BY sal;

SELECT e1.*
FROM emp e1
JOIN emp e2 ON e2.empno = 7934
WHERE e1.sal > e2.sal
ORDER BY e1.sal;

WITH TargetSalary AS (
    SELECT sal FROM emp WHERE empno = 7934
)
SELECT emp.* FROM emp, TargetSalary 
WHERE emp.sal > TargetSalary.sal
ORDER BY emp.sal;

SELECT * FROM solucion_ejercicio_22;

-- 23. Obtén los empleados que trabajan en Dallas o New York.
SELECT ename, loc FROM emp NATURAL JOIN dept WHERE loc = 'Dallas' OR loc = 'New York';
SELECT * FROM solucion_ejercicio_23;

-- 24. Halla los empleados cuyo salario supera o coincide con la media del salario de la empresa.
SELECT * FROM emp 
WHERE sal > (SELECT AVG(sal) FROM emp);

SELECT *
FROM (
    SELECT *, 
           AVG(sal) OVER () as avg_sal
    FROM emp
) t
WHERE sal > avg_sal;
SELECT * FROM solucion_ejercicio_24;

-- 25. Obtén los empleados del departamento 10 que tienen el mismo empleo que alguien del departamento de Ventas. 
-- Desconocemos el código de dicho departamento.
SELECT *
FROM emp
WHERE deptno = 10
  AND job IN (
      SELECT job 
      FROM emp 
      WHERE deptno = (SELECT deptno FROM dept WHERE dname = 'SALES')
  );
SELECT * FROM solucion_ejercicio_25;

-- 26. Halla los empleados que tienen por lo menos un empleado a su mando, ordenados inversamente por nombre.
SELECT ename FROM emp WHERE empno IN (SELECT mgr FROM emp) ORDER BY ename DESC;
SELECT * FROM solucion_ejercicio_26;

-- 27. Halla los empleados que no tienen ningún empleado a su mando
-- NOTE! This is incorrect: SELECT * FROM emp WHERE empno NOT IN (SELECT mgr FROM emp);
SELECT ename FROM emp WHERE empno NOT IN (SELECT mgr FROM emp WHERE mgr IS NOT NULL) ORDER BY ename DESC;
SELECT * FROM solucion_ejercicio_27;

-- 28. Obtén todos los departamentos sin empleados.
SELECT d.deptno, d.dname FROM dept d LEFT JOIN emp e ON d.deptno = e.deptno WHERE e.empno IS NULL;

SELECT d.deptno, d.dname
FROM dept d
WHERE NOT EXISTS (
    SELECT 1 
    FROM emp e 
    WHERE e.deptno = d.deptno
);
SELECT * FROM solucion_ejercicio_28;

-- 29. Muestra el código del empleado o empleados que más horas trabaja(n) en cada proyecto.
SELECT ep.empno, ep.prono, ep.hours
FROM emppro ep
WHERE ep.hours = (
    SELECT MAX(hours)
    FROM emppro
    WHERE prono = ep.prono
)
ORDER BY ep.hours;

SELECT ep.empno, ep.prono, ep.hours
FROM emppro ep
JOIN (
    SELECT prono, MAX(hours) AS max_hours
    FROM emppro
    GROUP BY prono
) mx ON ep.prono = mx.prono AND ep.hours = mx.max_hours
ORDER BY ep.prono;

SELECT empno, prono, hours
FROM (
    SELECT empno, prono, hours,
           RANK() OVER (PARTITION BY prono ORDER BY hours DESC) AS rnk
    FROM emppro
) ranked
WHERE rnk = 1
ORDER BY hours;

SELECT * FROM solucion_ejercicio_29 ORDER BY max_hours;

-- 30. Obtén los empleados cuyo salario supera al de todos sus compañeros de departamento.
SELECT e.empno, e.deptno, e.sal
FROM emp e
INNER JOIN (
    SELECT deptno, MAX(sal) as max_sal
    FROM emp
    GROUP BY deptno
) m ON e.deptno = m.deptno AND e.sal = m.max_sal;
SELECT * FROM solucion_ejercicio_30;

-- 31. Para cada puesto de trabajo el/los empleados que más ganan.
SELECT e.job, e.empno, e.sal
FROM emp e
INNER JOIN (
    SELECT job, MAX(sal) as max_sal
    FROM emp
    GROUP BY job
) m ON e.job = m.job AND e.sal = m.max_sal;

-- 32. ¿Qué empleados trabajan en ciudades de más de cinco letras? Ordena el resultado inversamente por ciudades y 
-- normalmente por los nombres de los empleados.
SELECT loc, ename
FROM emp NATURAL JOIN dept
WHERE LENGTH(loc) > 5
ORDER BY loc DESC, ename;
SELECT * FROM solucion_ejercicio_32;

-- 33. Para cada empleado muestra los proyectos en los que trabaja. Muestra el nombre del empleado y el nombre del 
-- proyecto.
SELECT e.empno, e.ename, p.pname
FROM emp e JOIN emppro ep ON ep.empno = e.empno JOIN pro p ON p.prono = ep.prono;
SELECT * FROM solucion_ejercicio_33;


-- 34. Muestra los proyectos controlados por cada departamento. Muestra el nombre del departamento y el nombre del 
-- proyecto. Deben aparecer todos los departamentos, incluso si no controla ningún departamento.
SELECT d.dname, p.pname
FROM dept d LEFT JOIN pro p ON d.deptno = p.deptno;
SELECT * FROM solucion_ejercicio_34;

-- 35. Obtén un listado en el que se reflejen los empleados y los nombres de sus jefes. En el listado deben aparecer 
-- todos los empleados, aunque no tengan jefe.
SELECT e1.ename, e2.ename as boss_name
FROM emp e1 LEFT JOIN emp e2 ON e1.mgr = e2.empno;
SELECT * FROM solucion_ejercicio_35;

-- 36. Los nombres de empleados contratados antes que su jefe.
SELECT e1.ename, e1.hiredate, e2.ename as jefe, e2.hiredate as fecha_jefe FROM emp e1 JOIN emp e2 ON e1.mgr = e2.empno WHERE e1.hiredate < e2.hiredate;
SELECT * FROM solucion_ejercicio_36;

-- 37. Para cada departamento, muestra los empleados que trabajan en proyectos vinculados a dicho departamento.
--  Muestra el nombre del departamento y el código de los empleados.
SELECT DISTINCT p.deptno, ep.empno FROM pro p LEFT JOIN emppro ep ON ep.prono = p.prono ORDER BY p.deptno;
SELECT p.deptno, ep.empno FROM pro p LEFT JOIN emppro ep ON ep.prono = p.prono GROUP BY p.deptno, ep.empno ORDER BY p.deptno;
SELECT * FROM solucion_ejercicio_37;

-- 38. Obtén el código de empleado, el nombre, el salario, el código del proyecto y las horas que le dedica cada 
-- empleado vinculado a algún proyecto, ordenado por el código del empleado.
SELECT e.empno, e.ename, e.sal, ep.prono, ep.hours FROM emp e JOIN emppro ep ON e.empno = ep.empno ORDER BY e.empno;
SELECT * FROM solucion_ejercicio_38;

-- 39. ¿Cuántos empleados hay en cada departamento, y cuál es la media del salario de cada uno? Indique el nombre del 
-- departamento para clarificar el resultado.
SELECT d.deptno, d.dname, COUNT(e.empno), COALESCE(AVG(e.sal),0) FROM dept d LEFT JOIN emp e ON e.deptno = d.deptno GROUP BY d.deptno;
SELECT * FROM solucion_ejercicio_39;

-- 40. Muestra la suma de salarios de los empleados de cada departamento que tienen un salario superior al salario medio 
-- de la empresa. Muestra el nombre del departamento.
SELECT d.deptno, d.dname, SUM(e.sal)
FROM emp e
NATURAL JOIN dept d
WHERE e.sal > (SELECT AVG(sal) FROM emp)
GROUP BY d.deptno, d.dname;
SELECT * FROM solucion_ejercicio_40;

-- 41. Para cada proyecto controlado por el departamento 30, indica su número, ciudad, número de empleados participantes 
-- en el proyecto, las horas dedicadas por el empleado que más ha trabajado, y las horas dedicadas por el que menos ha 
-- trabajado, y la diferencia entre ellas
SELECT p.prono, p.loc, COUNT(ep.prono), MAX(ep.hours), MIN(ep.hours), MAX(ep.hours) - MIN(ep.hours)
FROM pro p JOIN emppro ep ON ep.prono = p.prono
WHERE p.deptno = 30
GROUP BY p.prono;
SELECT * FROM solucion_ejercicio_41;

-- 42. Por cada departamento muestra el total de horas trabajadas en proyectos que lleva ese departamento,
-- agrupando por puesto de trabajo. Muestra el código de departamento y el nombre del puesto de trabajo
SELECT d.deptno, e.job, SUM(ep.hours)
FROM dept d
JOIN pro p ON d.deptno = p.deptno
JOIN emppro ep ON ep.prono = p.prono
JOIN emp e ON ep.empno = e.empno
GROUP BY d.deptno, e.job;
SELECT * FROM solucion_ejercicio_42;

-- 43. Para cada empleado muestra su nombre y cuántos empleados supervisa de cada puesto de trabajo.
SELECT e1.empno, e2.job, COUNT(e2.empno)
FROM emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr
GROUP BY e1.empno, e2.job;
SELECT * FROM solucion_ejercicio_43;

-- 44. Muestra para cada proyecto cuántas horas trabajan en total todos los empleados que tienen un salario superior al 
-- salario medio de la empresa. Muestra el nombre del proyecto.
SELECT p.pname , SUM(ep.hours)
FROM pro p
JOIN emppro ep ON ep.prono = p.prono
JOIN emp e ON ep.empno= e.empno
WHERE e.sal > (SELECT AVG(sal) FROM emp)
GROUP BY p.prono;
SELECT * FROM solucion_ejercicio_44;

-- 45. Para cada departamento, muestra su código, su nombre, el salario más alto y más bajo que cobran sus empleados, la 
-- diferencia entre estos dos salarios, y el número de proyectos a cargo del departamento.
SELECT d.deptno, d.dname, MAX(e.sal), MIN(e.sal),  MAX(e.sal) - MIN(e.sal), COUNT(DISTINCT p.prono)
FROM dept d
LEFT JOIN pro p ON d.deptno = p.deptno
LEFT JOIN emp e ON d.deptno = e.deptno
GROUP BY d.deptno;
SELECT * FROM solucion_ejercicio_45;

-- 46. Considerando empleados con salario menor de 5000, halla la media de los salarios de los departamentos cuyo 
-- salario mínimo supera a 900. Muestra también el código y el nombre de los departamentos.
SELECT d.dname, d.deptno, AVG(e.sal)
FROM dept d
JOIN emp e ON d.deptno = e.deptno
WHERE e.sal < 5000
GROUP BY d.deptno
HAVING MIN(e.sal) > 900;
SELECT * FROM solucion_ejercicio_46;

-- 47. Lista los empleados que tengan el mayor salario de su departamento, mostrando el nombre del empleado, su salario 
-- y el nombre del departamento.
SELECT e.ename, d.dname, sub.max
FROM emp e
JOIN dept d ON d.deptno = e.deptno
JOIN (
	SELECT deptno, MAX(sal) as max
	FROM emp
	GROUP BY deptno
) as sub ON sub.max = e.sal AND sub.deptno = e.deptno;
SELECT * FROM solucion_ejercicio_47;

-- 48. El puesto de trabajo con el salario medio más alto.
SELECT job, AVG(sal)
FROM emp
GROUP BY job
ORDER BY AVG(sal) DESC LIMIT 1;
SELECT * FROM solucion_ejercicio_48;

SELECT job, AVG(sal)
FROM emp
GROUP BY job
ORDER BY AVG(sal) DESC LIMIT 1;

-- 49. Para cada supervisor, muestra su subordinado(s) que más gana.
SELECT e1.empno as supervisor, e2.empno as suborinado, sub.max_sal as sal
FROM emp e1
JOIN (
	SELECT mgr, MAX(sal) as max_sal
	FROM emp
	GROUP BY mgr
) as sub ON sub.mgr = e1.empno
JOIN emp e2 ON e2.sal = sub.max_sal AND e2.mgr = sub.mgr
ORDER BY supervisor;
SELECT * FROM solucion_ejercicio_49;

-- 50. Deseamos saber cuántos empleados supervisa cada jefe. Para ello, Obtén un listado en el que se reflejen el código 
-- y el nombre de cada jefe, junto al número de empleados que supervisa directamente. Como puede haber empleados sin jefe, 
-- para estos se indicará sólo el número de ellos, y los valores restantes (código y nombre del jefe) se dejarán como 
-- nulos.
SELECT e.empno, e.ename, sub.emp_count
FROM emp e
RIGHT JOIN (
	SELECT mgr, COUNT(empno) as emp_count
	FROM emp
	GROUP BY mgr
) as sub ON sub.mgr = e.empno;
SELECT * FROM solucion_ejercicio_50;

-- 51. Hallar el/los departamento(s) cuya suma de salarios sea la más alta, mostrando esta suma de salarios y el nombre 
-- del departamento
SELECT d.deptno, d.dname, COALESCE(SUM(e.sal),0) as sum
FROM dept d
LEFT JOIN emp e ON e.deptno = d.deptno
GROUP BY d.deptno
ORDER BY sum DESC LIMIT 1;
SELECT * FROM solucion_ejercicio_51;

-- 52. Obtén los datos de los empleados que cobren los dos mayores salarios de la empresa. (Nota: Procure hacer la 
-- consulta de forma que sea fácil obtener los empleados de los N mayores salarios)
SELECT *
FROM emp
ORDER BY sal DESC LIMIT 2;
SELECT * FROM solucion_ejercicio_52;

-- 53. Obtén las localidades que no tienen departamentos sin empleados y en las que trabajen al menos cuatro empleados. 
-- Indica también el número de empleados que trabajan en esas localidades. (Nota: Por ejemplo, puede que en A Coruña 
-- existan dos departamentos, uno con más de cuatro empleados y otro sin empleados, en tal caso, A Coruña no debe aparecer 
-- en el resultado, puesto que tiene un departamento SIN EMPLEADOS, a pesar de tener otro con empleados Y tener más de 
-- cuatro empleados EN TOTAL. ATENCIÓN, la restricción de que tienen que ser cuatro empleados se refiere a la totalidad de 
-- los departamentos de la localidad.)
SELECT d.loc, d.deptno, COUNT(e.empno)
FROM dept d
JOIN emp e ON d.deptno = e.deptno
WHERE d.loc NOT IN(
	SELECT loc
	FROM dept sub_d
	LEFT JOIN emp sub_e ON sub_d.deptno = sub_e.deptno
	WHERE sub_e.empno IS NULL
)
GROUP BY d.loc, d.deptno
HAVING COUNT(e.empno) > 3;
SELECT * FROM solucion_ejercicio_53;

-- 54. Obtén un listado de todos los empleados (código, nombre) donde aparezca el total de horas dedicado a proyectos. 
-- Deben aparecer todos los empleados, aunque no trabajen en proyectos.
SELECT e.empno, e.ename, COALESCE(SUM(ep.hours),0)
FROM emp e
LEFT JOIN emppro ep ON e.empno = ep.empno
GROUP BY e.empno;
SELECT * FROM solucion_ejercicio_54;

-- 55. Nombre del departamento(s) que tiene(n) el mayor número de supervisores.
SELECT d.deptno, COUNT(DISTINCT e1.empno) as count
FROM dept d
JOIN emp e1 ON d.deptno = e1.deptno
JOIN emp e2 ON e1.empno = e2.mgr
GROUP BY d.deptno
ORDER BY count DESC LIMIT 1;

SELECT d.dname, COUNT(DISTINCT e1.empno) as count
FROM dept d
LEFT JOIN emp e1 ON d.deptno = e1.deptno
LEFT JOIN emp e2 ON e1.empno = e2.mgr
WHERE e2.empno IS NOT NULL OR e2.empno IS NULL AND e1.empno IS NULL
GROUP BY d.deptno
ORDER BY count DESC LIMIT 1;


SELECT 
    d.dname, 
    COUNT(s.mgr) AS supervisor_count
FROM dept d
LEFT JOIN (
    SELECT DISTINCT mgr 
    FROM emp 
    WHERE mgr IS NOT NULL
) s ON d.deptno = (SELECT deptno FROM emp WHERE empno = s.mgr)
GROUP BY d.dname
ORDER BY supervisor_count;

SELECT 
    d.dname, 
    COUNT(s.mgr) AS supervisor_count
FROM dept d
LEFT JOIN (
    SELECT DISTINCT mgr 
    FROM emp 
    WHERE mgr IS NOT NULL
) s ON d.deptno = (SELECT deptno FROM emp WHERE empno = s.mgr)
GROUP BY d.dname
HAVING supervisor_count = (
    SELECT COUNT(DISTINCT e3.empno)
    FROM emp e3
    INNER JOIN emp e4 ON e3.empno = e4.mgr
    GROUP BY e3.deptno
    ORDER BY 1 DESC
    LIMIT 1
);

WITH DeptCounts AS (
    SELECT 
        d.dname, 
        COUNT(DISTINCT e1.empno) AS supervisor_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT e1.empno) DESC) as rnk
    FROM dept d
    LEFT JOIN emp e1 ON d.deptno = e1.deptno
	LEFT JOIN emp e2 ON e1.empno = e2.mgr
	WHERE e2.empno IS NOT NULL OR e2.empno IS NULL AND e1.empno IS NULL    GROUP BY d.dname
)
SELECT dname, supervisor_count
FROM DeptCounts
WHERE rnk = 1;

SELECT * FROM solucion_ejercicio_55;

-- 56. Nombres de empleados que trabajan solos en algún proyecto
SELECT e.empno, e.ename
FROM emp e
NATURAL JOIN emppro ep
WHERE ep.prono IN (
	SELECT prono
	FROM emppro 
	GROUP BY prono 
	HAVING COUNT(empno) = 1
);

SELECT empno, ename
FROM (
    SELECT 
        e.empno, 
        e.ename,
        COUNT(ep.empno) OVER(PARTITION BY ep.prono) as workers_on_proj
    FROM emp e
    NATURAL JOIN emppro ep
) t
WHERE workers_on_proj = 1;

SELECT * FROM solucion_ejercicio_56;

-- 57. Para cada empleado, número, nombre y contar cuantos ganan menos que él (si no hay ninguno, debe aparecer un 0)
SELECT 
    empno, 
    ename,
    COUNT(*) OVER (ORDER BY sal RANGE BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS count_earning_less
FROM emp
ORDER BY count_earning_less;

SELECT 
    empno, 
    ename,
	RANK() OVER (ORDER BY sal) - 1 AS count_earning_less
FROM emp
ORDER BY count_earning_less;

SELECT 
    e1.empno, 
    e1.ename,
    (SELECT COUNT(*) 
     FROM emp e2 
     WHERE e2.sal < e1.sal) AS count_earning_less
FROM emp e1
ORDER BY count_earning_less;

SELECT 
    e1.empno, 
    e1.ename, 
    COUNT(e2.empno) AS count_earning_less
FROM emp e1
LEFT JOIN emp e2 ON e2.sal < e1.sal
GROUP BY e1.empno, e1.ename
ORDER BY e1.empno;

SELECT * FROM solucion_ejercicio_57 ORDER BY empno;

-- 58. Para cada empleado, número, nombre y contar cuantos (descontando a él mismo) ganan lo mismo o menos que él (si no 
-- hay ninguno, debe aparecer un 0)
SELECT 
    empno, 
    ename,
    COUNT(*) OVER (ORDER BY sal RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - 1 AS count_earning_less
FROM emp
ORDER BY empno;

SELECT 
    e1.empno, 
    e1.ename,
    (SELECT COUNT(*) 
     FROM emp e2 
     WHERE e2.sal <= e1.sal) - 1 AS count_earning_less
FROM emp e1
ORDER BY count_earning_less;

SELECT 
    e1.empno, 
    e1.ename, 
    COUNT(e2.empno) - 1 AS count_earning_less
FROM emp e1
LEFT JOIN emp e2 ON e2.sal <= e1.sal
GROUP BY e1.empno, e1.ename
ORDER BY count_earning_less;

SELECT * FROM solucion_ejercicio_58 ORDER BY empno;

-- 59. Para cada jefe mostrar cuántos empleados supervisa en cada departamento (los empleados supervisados no tienen por 
-- qué ser del mismo departamento que el supervisor). Mostrar nombre de empleado y código departamento (de los empleados 
-- supervisores).
SELECT e1.empno, e1.ename, e2.deptno, COUNT(e2.empno)
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr
GROUP BY e1.empno, e1.ename, e2.deptno;

SELECT * FROM solucion_ejercicio_59;

-- 60. Ídem mostrando todos los empleados, y en aquellos que no son jefes, mostrando un cero en el número de empleados 
-- supervisados.
SELECT e1.empno, e1.ename, COUNT(e2.empno)
FROM emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr
GROUP BY e1.empno;

SELECT * FROM solucion_ejercicio_60;

-- 61. Para cada departamento que tenga, por lo menos, dos empleados sin comisión, muestra el nombre del departamento, y 
-- cuántos empleados tiene en total (con y sin comisión).
SELECT d.dname, COUNT(e.empno)
FROM dept d
NATURAL JOIN emp e
WHERE d.deptno IN (
	SELECT deptno
	FROM emp
	WHERE comm IS NULL
	GROUP BY deptno
	HAVING COUNT(empno) > 1
)
GROUP BY d.deptno;

SELECT d.dname, COUNT(e.empno)
FROM dept d
NATURAL JOIN emp e
WHERE EXISTS (
	SELECT deptno
	FROM emp
	WHERE comm IS NULL AND deptno = d.deptno
	GROUP BY deptno
	HAVING COUNT(empno) > 1
)
GROUP BY d.deptno;

WITH TargetDepts AS (
    SELECT deptno
    FROM emp
    WHERE comm IS NULL
    GROUP BY deptno
    HAVING COUNT(*) > 1
)
SELECT d.dname, COUNT(e.empno) AS total_employees
FROM dept d
JOIN emp e ON d.deptno = e.deptno
JOIN TargetDepts td ON d.deptno = td.deptno
GROUP BY d.dname;

SELECT * FROM solucion_ejercicio_61;

-- 62. ¿Cuál es la ciudad (o ciudades, si hay más de una) en la que hasta el momento se han trabajado más horas en 
-- proyectos? Indica el nombre de la ciudad, y el número de horas.
SELECT 
    loc,
    SUM(hours) as total_hours
FROM pro
NATURAL JOIN emppro
GROUP BY loc
HAVING SUM(hours) = (
    SELECT 
        MAX(sum_h)
    FROM (
    	SELECT SUM(hours) as sum_h
    	FROM pro
	    NATURAL JOIN emppro
	    GROUP BY loc
    ) as totals  
);

WITH RankedLocations AS (
    SELECT 
        loc,
        SUM(hours) as total_hours,
        RANK() OVER (ORDER BY SUM(hours) DESC) as rnk
    FROM pro
    NATURAL JOIN emppro
    GROUP BY loc
)
SELECT 
    loc, 
    total_hours, 
    rnk
FROM RankedLocations
WHERE rnk = 1;

SELECT * FROM solucion_ejercicio_62;

-- 63. Muestra para cada proyecto su código y, de los empleados que trabajan en dicho proyecto, el nombre del empleado 
-- que más gana de cada puesto de trabajo.
SELECT p.prono, e.job, e.ename, e.sal
FROM pro p
NATURAL JOIN emppro ep
JOIN emp e ON e.empno = ep.empno
JOIN (
	SELECT prono, e.job, MAX(e.sal) as max_sal
	FROM pro
	NATURAL JOIN emppro ep
	JOIN emp e ON e.empno = ep.empno
	GROUP BY prono, e.job
) as s ON s.prono = p.prono AND e.job = s.job AND e.sal = s.max_sal
ORDER BY ename;

SELECT * FROM (
	SELECT p.prono,
		e.job,
		e.ename,
		RANK() OVER (
	    	PARTITION BY p.prono, e.job 
	    	ORDER BY e.sal DESC
	   	) as rnk
	FROM pro p
	NATURAL JOIN emppro ep
	JOIN emp e ON ep.empno = e.empno
) ranked WHERE rnk = 1
ORDER BY ename;

SELECT * FROM solucion_ejercicio_63 ORDER BY ename;

-- 64. Para cada empleado, Obtén su código y su nombre, y el código y nombre del proyecto al que dedica más horas ese 
-- empleado. Muestra también las horas, y ordena el resultado por nombre de empleado.
SELECT empno, ename, prono, pname, hours
FROM (
	SELECT e.empno, e.ename, p.prono, p.pname, emp.hours,
		RANK() OVER(PARTITION BY e.empno ORDER BY emp.hours DESC) as rnk
	FROM emp e
	NATURAL LEFT JOIN emppro emp
	LEFT JOIN pro p ON p.prono = emp.prono
) sub WHERE rnk = 1;

SELECT * FROM solucion_ejercicio_64 ;

-- 65. Considerando sólo los empleados que tienen el máximo salario de cada puesto de trabajo, muestra para cada 
-- departamento su nombre y cuántos de dichos empleados trabajan en ese departamento.
SELECT d.dname, COUNT(e.empno)
FROM dept d
NATURAL JOIN emp e
JOIN (
	SELECT job, MAX(sal) as max_sal
	FROM emp
	GROUP BY job
) sub ON sub.job = e.job AND e.sal = sub.max_sal
GROUP BY d.deptno;

SELECT * FROM solucion_ejercicio_65;

-- 66. Para cada empleado muestra su nombre, cuántos empleados supervisa en total, cuántos con comisión y cuántos sin 
-- comisión. Si el empleado no supervisa a nadie, o no supervisa empleados sin/con comisión, se debe mostrar un cero en el 
-- número correspondiente.
SELECT e1.empno as empleado, COUNT(e2.empno) as supervisa, COUNT(e2.comm) as 'con comision', COUNT(e2.empno) - COUNT(e2.comm) as 'sin comision'
FROM emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr
GROUP BY e1.empno;

SELECT * FROM solucion_ejercicio_66;

-- 67. Muestra el nombre y trabajo de los empleados que son supervisores y que tienen el mismo trabajo que todos sus 
-- subordinados
SELECT e1.ename, e1.job
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr AND e1.job = e2.job;

SELECT * FROM solucion_ejercicio_67;

-- 68. Para cada departamento muestra cuántos jefes tiene y cuántos subordinados tienen esos jefes (los subordinados no 
-- tienen por qué ser del mismo departamento que el jefe). Deben aparecer todos los departamentos.
SELECT d.deptno, COUNT(DISTINCT e1.empno), COUNT(DISTINCT e2.empno)
FROM dept d
NATURAL LEFT JOIN emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr
WHERE e1.empno IS NULL OR e2.empno IS NOT NULL
GROUP BY d.deptno;

SELECT * FROM solucion_ejercicio_68;

-- 69. Muestra el nombre de los departamentos con más de tres empleados de los cuales al menos dos son jefes
SELECT d.deptno, d.dname,  COUNT(DISTINCT e1.empno), COUNT(DISTINCT e2.mgr)
FROM dept d
NATURAL LEFT JOIN emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr
GROUP BY d.deptno
HAVING COUNT(DISTINCT e1.empno) > 3 AND COUNT(DISTINCT e2.mgr) > 1;

SELECT * FROM solucion_ejercicio_69;

-- 70. Para cada jefe, muestra su nombre y cuántos empleados supervisa en departamentos diferentes al suyo. Si un jefe 
-- no supervisa a ningún empleado de otro departamento, muestra un cero.
SELECT e1.ename, COUNT(e2.empno)
FROM emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr AND e1.deptno != e2.deptno
GROUP BY e1.empno;

SELECT * FROM solucion_ejercicio_70;

SELECT e1.ename, COUNT(e2.empno)
FROM emp e1
LEFT JOIN emp e2 ON e1.empno = e2.mgr AND e1.deptno != e2.deptno
WHERE e1.empno IN (SELECT mgr FROM emp WHERE mgr IS NOT NULL)
GROUP BY e1.empno, e1.ename;

-- 71. Muestra los empleados contratados en Junio o en el año 1982.
SELECT * FROM emp WHERE YEAR(hiredate) = 1982 OR MONTH(hiredate) = 6;
SELECT * FROM solucion_ejercicio_71;


-- 72. Obtén la salida siguiente:
-- CODIGO	|	NOMBRE Y EMPLEO
-- 7369 	|	SMITH trabaja de CLERK
-- 7499 	|	ALLEN trabaja de SALESMAN
-- 7521 	|	WARD trabaja de SALESMAN
-- ...		|	...
SELECT empno, CONCAT(ename, ' trabaja de ', job) FROM emp;

-- 73. (DB jardineria) Muestra el código del pedido, los días que tardó en entregarse 
-- cada pedido y etiqueta los que fueron entregados con retraso o al día.
USE jardineria;

SELECT
	codigo_pedido,
	TIMESTAMPDIFF(DAY, fecha_pedido, fecha_entrega),
	CASE 
        WHEN fecha_entrega > fecha_esperada THEN 'delayed'
        WHEN fecha_entrega = fecha_esperada THEN 'on time'
        WHEN fecha_entrega < fecha_esperada THEN 'soon' -- or 'early'
        ELSE 'pending'
    END AS status
FROM pedido
WHERE fecha_entrega IS NOT NULL;

SELECT * FROM solucion_ejercicio_73;

-- 74. Muestra el nombre, la fecha de contratación, la fecha actual y los años de 
-- antigüedad de todos los empleados.
USE basic_employees;

SELECT ename, hiredate, CURDATE(), TIMESTAMPDIFF(YEAR, hiredate, CURDATE())
FROM emp;
SELECT * FROM solucion_ejercicio_74;

-- 75. (DB jardineria) Obtén el año, el mes y el número de pedidos que se hicieron cada mes.
USE jardineria;

SELECT YEAR(fecha_pedido) as ano, MONTH(fecha_pedido) as mes, COUNT(codigo_pedido)
FROM pedido
GROUP BY YEAR(fecha_pedido), MONTH(fecha_pedido);
SELECT * FROM solucion_ejercicio_75;

-- 76. (DB jardineria) Pedidos que se hicieron el mismo mes de cada año. Ordenados por año y por mes.
-- Idk what this is asking for?
SELECT p1.*
FROM pedido p1
JOIN pedido p2 ON MONTH(p1.fecha_entrega) = MONTH(p2.fecha_entrega) AND YEAR(p1.fecha_entrega) = YEAR(p2.fecha_entrega)
ORDER BY fecha_pedido DESC;

SELECT * FROM solucion_ejercicio_76;

-- 77. (DB jardineria) Muestra el código del pedido, el nombre del cliente, tres formatos distintos
-- de la fecha en la que se hizo el pedido ('20/01/2009', '2009-01', 'January 2009'), la fecha esperada,
-- fecha de entrega y el nombre del día de la semana que fue entregado; de todos los pedidos cuya fecha esperada
-- sea 7 días después de la fecha de pedido.
SELECT
	p.codigo_pedido,
	c.nombre_cliente,
	DATE_FORMAT(p.fecha_pedido, '%d/%m/%Y'),
	DATE_FORMAT(p.fecha_pedido, '%Y-%m'),
	DATE_FORMAT(p.fecha_pedido, '%M %Y'),
	p.fecha_esperada,
	p.fecha_entrega,
	DAYNAME(p.fecha_entrega)
FROM pedido p
NATURAL JOIN cliente c
WHERE TIMESTAMPDIFF(DAY, fecha_pedido, fecha_esperada) = 7;

SELECT * FROM solucion_ejercicio_77;

-- 78. Obtén los códigos, nombres y salarios de los empleados vinculados a algún proyecto, además de obtener el código 
-- y el nombre del proyecto, y el número de horas.
USE basic_employees;

SELECT e.empno, e.ename, e.sal, p.prono, p.pname, ep.hours
FROM emp e
NATURAL JOIN emppro ep
JOIN pro p ON ep.prono = p.prono;

SELECT * FROM solucion_ejercicio_78;

-- 79. (DB jardineria) Muestra el código, la fecha de pedido y el número de la semana para todos los pedidos 
-- hechos en la última semana de cada año. (Nota: Si en un año hay registros solo hasta finales de mayo, ese será 
-- la última semana de ese año).
USE jardineria;
SELECT
	p.codigo_pedido,
	p.fecha_pedido,
	WEEK(p.fecha_pedido)
FROM pedido p
WHERE  WEEK(p.fecha_pedido) = (SELECT MAX(WEEK(fecha_pedido)) FROM pedido WHERE YEAR(fecha_pedido) = YEAR(p.fecha_pedido));

SELECT * FROM solucion_ejercicio_79;

-- 80. (DB jardineria) Obtén los meses en los que no hubo pedidos. Muéstralo en un formato en el que se pueda ver el año al que
-- pertenece ese mes.
-- Meses sin pedidos (con año visible)
SELECT 
    CONCAT(all_months.anio, '-', all_months.mes) as mes
FROM (
    SELECT 
        YEAR(fecha_pedido) AS anio,
        MONTH(fecha_pedido) AS mes
    FROM pedido
    GROUP BY YEAR(fecha_pedido), MONTH(fecha_pedido)
) AS meses_con_pedidos
RIGHT JOIN (
    SELECT DISTINCT
        YEAR(fecha_pedido) AS anio,
        n.mes
    FROM pedido
    CROSS JOIN (
        SELECT 1 AS mes UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
        UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8
        UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12
    ) n
) AS all_months
ON meses_con_pedidos.anio = all_months.anio AND meses_con_pedidos.mes = all_months.mes
WHERE meses_con_pedidos.mes IS NULL
ORDER BY all_months.anio, all_months.mes;

SELECT * FROM solucion_ejercicio_80;

-- 81. Realice un producto cartesiano de las tablas emp y dept.
USE basic_employees;

SELECT *
FROM emp
CROSS JOIN dept;

SELECT * FROM solucion_ejercicio_81;

-- 82. Realiza un equijoin de las tablas emp y dept.
USE basic_employees;

SELECT *
FROM emp 
NATURAL JOIN dept;

SELECT * FROM solucion_ejercicio_82;

-- 83. Obtén información en la que se reflejen, en cada fila, los nombres, empleos y salarios, tanto de los que superan 
-- el salario de Allen, como los del propio Allen:
-- ENAME 	|	JOB		|	SAL 	| 	ENAME 	| 	JOB  		|	SAL
-- JONES 	|	MANAGER |	2,975 	|	ALLEN 	|	SALESMAN	| 	1,600
-- BLAKE 	|	MANAGER |	2,850 	|	ALLEN 	|	SALESMAN 	|	1,600
-- ...		|	...		|	...		|	...		|	...			|	...
SELECT e1.ename, e1.job, e1.sal, e2.ename, e2.job, e2.sal
FROM emp e1
CROSS JOIN (SELECT ename, job, sal FROM emp WHERE ename = 'ALLEN') e2
WHERE e1.sal >= e2.sal AND e1.ename != e2.ename
ORDER BY e1.ename;

SELECT e1.ename, e1.job, e1.sal, e2.ename, e2.job, e2.sal
FROM emp e1
JOIN emp e2 ON e2.ename = 'ALLEN'
WHERE e1.sal >= e2.sal AND e1.ename != e2.ename
ORDER BY e1.ename;

SELECT * FROM solucion_ejercicio_83 ORDER BY ename;

-- 84. Obtén el nombre de cada empleado y el de su supervisor:
-- EMPNO 	|	ENAME 	|	CDG_MNG 	|	MNG
-- 7788 	|	SCOTT 	|	7566 		|	JONES
-- 7902 	|	FORD 	|	7566 		|	JONES
-- ...		|	...		|	...			|	...
SELECT e2.empno as cod_empleado, e2.ename as empleado, e1.empno as cod_supervisor , e1.ename as supervisor
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr ORDER BY cod_empleado;

SELECT * FROM solucion_ejercicio_84 ORDER BY cod_empleado;

-- 85. Obtener las referencias de los empleados con los datos de sus departamentos, para todos los empleados y todos los 
-- departamentos. Todos es “todos los que pueda haber”.
-- EMPNO	|	ENAME	| 	DEPTNO 	|	DNAME
-- 7782 	|	CLARK 	|	10 		|	ACCOUNTING
-- 7839 	|	KING 	|	10 		|	ACCOUNTING
-- ...		|	...		|	...		|	...
SELECT empno, ename, deptno, dname
FROM emp
NATURAL JOIN dept ORDER BY deptno;

SELECT * FROM solucion_ejercicio_85;

-- 86. Obtén los salarios mínimos y el código de cada departamento.
SELECT dname, MIN(sal)
FROM dept
NATURAL JOIN emp
GROUP BY dname;

SELECT * FROM solucion_ejercicio_86;

-- 87. Obtén el salario más alto de entre los salarios mínimos de cada departamento.
SELECT MAX(s)
FROM (
	SELECT MIN(sal) as s
	FROM emp
	GROUP BY deptno
) as s;

SELECT * FROM solucion_ejercicio_87;

-- 88. Obtén los códigos de los supervisores y el salario máximo y mínimo de los empleados que supervisa, para los 
-- empleados que no son del departamento 10, y el salario mínimo de los empleados que supervisa es mayor que 1000.
SELECT e1.empno, MAX(e2.sal), MIN(e2.sal)
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr
WHERE e2.deptno != 10 
GROUP BY e1.empno
HAVING MIN(e2.sal) > 1000;

SELECT * FROM solucion_ejercicio_88;

-- 89. Obtener el código de los supervisores que tienen supervisor, mostrando el salario máximo de todos sus empleados 
-- y el salario mínimo calculado únicamente entre aquellos empleados con salario superior a 1000, aunque el supervisor 
-- tenga otros empleados con salario inferior.
SELECT e1.empno, MAX(e2.sal), MIN(e3.sal)
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr
JOIN emp e3 ON e1.empno = e3.mgr
WHERE e3.sal > 1000 AND e1.mgr IS NOT NULL
GROUP BY e1.empno;

SELECT
    e1.empno,
    MAX(e2.sal)                                  AS max_sal,
    MIN(CASE WHEN e2.sal > 1000 THEN e2.sal END) AS min_sal
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr
WHERE e1.mgr IS NOT NULL
GROUP BY e1.empno;

SELECT * FROM solucion_ejercicio_89;

-- 90. Obtén los códigos, nombres, salarios y departamentos de los empleados cuyo salario supera al de la media de los 
-- salarios de los empleados.
SELECT empno, ename, sal, deptno
FROM emp
WHERE sal > (SELECT AVG(sal) FROM emp);

SELECT * FROM solucion_ejercicio_90;

-- 91. Obtén los códigos, nombres, salarios y departamentos de los empleados cuyo salario supera al de sus compañeros de 
-- departamento.
SELECT empno, ename, sal, deptno
FROM (
	SELECT empno, ename, sal, deptno,
	RANK() OVER (PARTITION BY deptno ORDER BY sal DESC) AS rnk
	FROM emp
) as s
WHERE rnk = 1;

SELECT e.empno, e.ename, e.sal, e.deptno
FROM emp e
JOIN (
	SELECT deptno, MAX(sal) as sal
	FROM emp
	GROUP BY deptno
) as s ON e.deptno = s.deptno AND e.sal = s.sal;

SELECT * FROM solucion_ejercicio_91;

-- 92. Obtén el nombre, salario y comisión de los empleados que son supervisores.
SELECT ename, sal, comm
FROM emp
WHERE empno IN (
	SELECT mgr
	FROM emp
	WHERE mgr IS NOT NULL
) ORDER BY ename;

SELECT e1.ename, e1.sal, e1.comm
FROM emp e1
WHERE EXISTS (SELECT 1 FROM emp e2 WHERE e2.mgr = e1.empno)
ORDER BY e1.ename;

SELECT DISTINCT * FROM solucion_ejercicio_92 ORDER BY ename;

-- 93. Obtén el nombre, salario y comisión de los empleados que no son supervisores.
SELECT e.ename, e.sal, e.comm
FROM emp e
WHERE NOT EXISTS (SELECT 1 FROM emp WHERE mgr = e.empno);
SELECT * FROM solucion_ejercicio_93;

-- 94. Halla los nombres y la localidad de los departamentos que no tienen empleados.
SELECT d.deptno, d.dname, d.loc
FROM dept d
WHERE NOT EXISTS (SELECT 1 FROM emp WHERE deptno = d.deptno);

SELECT * FROM solucion_ejercicio_94;

-- 95. Obtén los nombres, empleos, salario y comisión de los empleados cuyo salario es mayor que el de alguno de los 
-- comerciales, ordenando por el salario.

SELECT * FROM solucion_ejercicio_95;

-- 96. Obtén los nombres, empleos, salario y comisión de los empleados cuyo salario es mayor que el de los comerciales, 
-- ordenando por el salario.
SELECT ename, job, sal, comm
FROM emp
WHERE sal > (
	SELECT MAX(sal)
	FROM emp 
	WHERE job = 'SALESMAN')
ORDER BY sal;

SELECT * FROM solucion_ejercicio_96 ORDER BY sal;

-- 97. Obtén el nombre del departamento que posee la mayor media de los salarios de los empleados, y el valor de esa 
-- media:
-- DEPTNO 	|	DNAME		| 	MEDIA
-- 10 		|	ACCOUNTING 	|	2916.66667
-- ...		|	...			|	...
SELECT deptno, dname, AVG(sal) as avg_sal
FROM dept
NATURAL JOIN emp
GROUP BY deptno, dname
ORDER BY avg_sal DESC LIMIT 1;

SELECT * FROM solucion_ejercicio_97;

-- 98. Obtén los códigos y los nombres de los departamentos que se responsabilizan de proyectos que se realizan en la 
-- misma ciudad en la que tiene su sede el departamento, pero de forma que aparezca en el resultado, para cada departamento, 
-- el número de proyectos que cumplen esa condición. Resuelve el ejercicio con tres alternativas de JOIN distintas.
-- Alternativa 1:
SELECT d.deptno, d.dname, COUNT(p.prono) 
FROM dept d
NATURAL JOIN pro p
WHERE d.loc = p.loc
GROUP BY d.deptno, d.dname;

-- Alternativa 2:
SELECT d.deptno, d.dname, COUNT(p.prono) 
FROM dept d
JOIN pro p ON d.deptno = p.deptno AND d.loc = p.loc
GROUP BY d.deptno, d.dname;

-- Alternativa 3:
SELECT d.deptno, d.dname, COUNT(p.prono) AS num_projects
FROM dept d
LEFT JOIN pro p ON d.deptno = p.deptno AND d.loc = p.loc
GROUP BY d.deptno, d.dname
HAVING COUNT(p.prono) > 0;

SELECT * FROM solucion_ejercicio_98;

-- 99. Modifica la consulta anterior para que, en vez de aparecer el número de proyectos que verifican la condición, 
-- aparezca una fila para cada departamento y para cada proyecto que la cumplen, en la que se incluye el código y el 
-- nombre, tanto del departamento como del proyecto.
SELECT d.deptno, d.dname, p.prono, p.pname, d.loc
FROM dept d
JOIN pro p ON d.deptno = p.deptno AND d.loc = p.loc

SELECT * FROM solucion_ejercicio_99;

-- 100. Obtén el código de empleado, el nombre, el salario, el código de proyecto y las horas que le dedica cada 
-- empleado vinculado a algún proyecto, ordenado por código de empleado. Resuelve el ejercicio con tres alternativas de 
-- JOIN distintas.
-- Alternativa 1:
SELECT empno, ename, sal, prono, hours
FROM emp
NATURAL JOIN emppro
ORDER BY empno;

-- Alternativa 2:
SELECT e.empno, ename, sal, prono, hours
FROM emp e
JOIN emppro ep ON e.empno = ep.empno
ORDER BY e.empno;

-- Alternativa 3:
SELECT empno, ename, sal, prono, hours
FROM emp
NATURAL LEFT JOIN emppro
WHERE prono IS NOT NULL
ORDER BY empno;

SELECT * FROM solucion_ejercicio_100;

-- 101. Queremos obtener los datos de todos los empleados (código, nombre y salario) y a la vez los de los proyectos 
-- (código y horas) vinculados a algún empleado. Resuelve el ejercicio con tres alternativas de JOIN distintas.
-- Alternativa 1:
SELECT empno, ename, sal, prono, hours
FROM emp
NATURAL JOIN emppro
ORDER BY empno;

-- Alternativa 2:
SELECT e.empno, ename, sal, prono, hours
FROM emp e
LEFT JOIN emppro ep ON e.empno = ep.empno
WHERE prono IS NOT NULL
ORDER BY e.empno;

-- Alternativa 3:
SELECT e.empno, ename, sal, prono, hours
FROM emp e
JOIN emppro ep ON e.empno = ep.empno
ORDER BY e.empno;

SELECT * FROM solucion_ejercicio_101;

-- 102. Se desea obtener un listado de los empleados que están vinculados a un proyecto, de las horas de dedicación al 
-- mismo, con los datos del proyecto (código, nombre) y los del departamento responsabilizado de los proyectos (código, 
-- nombre).
SELECT e.empno, e.ename, e.sal, ep.hours, p.prono, p.pname, d.deptno, d.dname
FROM emp e
NATURAL JOIN emppro ep
JOIN pro p ON ep.prono = p.prono
JOIN dept d ON p.deptno = d.deptno
ORDER BY empno;

SELECT * FROM solucion_ejercicio_102 ORDER BY empno;

-- 103. Datos de los empleados vinculados a un proyecto (código, nombre y salario), con el código y nombre de los 
-- departamentos que están responsabilizados de esos proyectos, y el código y nombre de los departamentos a los que 
-- pertenecen los empleados involucrados.
SELECT e.empno, e.ename, e.sal, ep.hours, p.prono, p.pname, d.deptno, d.dname, d1.deptno, d1.dname
FROM emp e
NATURAL JOIN emppro ep
JOIN pro p ON ep.prono = p.prono
JOIN dept d ON p.deptno = d.deptno
JOIN dept d1 ON e.deptno = d1.deptno
ORDER BY empno;

SELECT * FROM solucion_ejercicio_103 ORDER BY empno;

-- 104. Se desea obtener un listado de los empleados que están vinculados a un proyecto, de las horas de dedicación al 
-- mismo, con los datos del proyecto (código, nombre) y los de los departamentos (código, nombre), estén o no responsabilizados 
-- de proyectos.
SELECT e.empno, e.ename, ep.hours, p.prono, p.pname, d.deptno, d.dname
FROM emp e
NATURAL JOIN emppro ep
JOIN pro p ON ep.prono = p.prono
RIGHT JOIN dept d ON p.deptno = d.deptno
ORDER BY empno;

SELECT * FROM solucion_ejercicio_104 ORDER BY empno;

-- 105. Obtén los datos de todos los empleados y de todos los departamentos, incluyendo los datos de los proyectos 
-- vinculados a empleados y departamentos que están responsabilizados de ellos.
SELECT e.empno, e.ename, e.sal, ep.hours, p.prono, p.pname, d.deptno, d.dname
FROM emp e
NATURAL LEFT JOIN emppro ep
LEFT JOIN pro p ON ep.prono = p.prono
LEFT JOIN dept d ON p.deptno = d.deptno
UNION
SELECT e.empno, e.ename, e.sal, ep.hours, p.prono, p.pname, d.deptno, d.dname
FROM emp e
NATURAL LEFT JOIN emppro ep
LEFT JOIN pro p ON ep.prono = p.prono
RIGHT JOIN dept d ON p.deptno = d.deptno
ORDER BY empno;

SELECT * FROM solucion_ejercicio_105 ORDER BY empno;

-- 106. Obtén los datos de los departamentos que, o bien están responsabilizados de proyectos, o bien tienen la sede en 
-- la misma ciudad en la que se realiza un proyecto.
SELECT deptno, dname, loc
FROM dept d
WHERE EXISTS (
	SELECT 1
	FROM pro
	WHERE loc = d.loc
) OR EXISTS (
	SELECT 1 
	FROM pro 
	WHERE d.deptno = deptno
); 

SELECT * FROM solucion_ejercicio_106;

-- 107. Obtén los datos de los departamentos que están responsabilizados de proyectos y que tienen la sede en la misma 
-- ciudad en la que se realiza un proyecto.
SELECT deptno, dname, loc
FROM dept d
WHERE EXISTS (
	SELECT 1
	FROM pro
	WHERE loc = d.loc
) AND EXISTS (
	SELECT 1 
	FROM pro 
	WHERE d.deptno = deptno
); 

SELECT * FROM solucion_ejercicio_107;

-- 108. Obtén los datos de los departamentos que están responsabilizados de proyectos que se realizan en la misma ciudad 
-- en la que tienen su sede. Resuelve usando 3 alternativas.
-- Alternativa 1:
SELECT deptno, dname, loc
FROM dept d
WHERE EXISTS (
	SELECT 1
	FROM pro
	WHERE loc = d.loc AND deptno = d.deptno
);

-- Alternativa 2:
SELECT DISTINCT d.deptno, dname, d.loc
FROM dept d
JOIN pro p ON p.loc = d.loc AND p.deptno = d.deptno;

-- Alternativa 3:
SELECT deptno, dname, loc
FROM dept d
WHERE d.deptno IN (
    SELECT p.deptno
    FROM pro p
    WHERE p.loc = d.loc
);

SELECT * FROM solucion_ejercicio_108;

-- 109. Obtén los códigos, nombres, salarios y departamentos de los empleados cuyo salario supera el salario mínimo de 
-- los empleados, indicando en cada fila dicho mínimo, y la diferencia entre el salario de cada uno y el mínimo, ordenados 
-- por salario y por código de empleado:
WITH min_sal_cte AS (
    SELECT MIN(sal) as m_sal FROM emp
)
SELECT 
    e.empno, 
    e.ename, 
    e.sal, 
    e.deptno, 
    e.sal - m.m_sal AS diff, 
    m.m_sal
FROM emp e
CROSS JOIN min_sal_cte m
WHERE e.sal > m.m_sal
ORDER BY e.sal, e.empno;

SELECT * FROM (
    SELECT 
        empno, 
        ename, 
        sal, 
        deptno, 
        sal - MIN(sal) OVER() AS diff, 
        MIN(sal) OVER() AS min_sal
    FROM emp
) t
WHERE sal > min_sal
ORDER BY sal, empno;

SELECT * FROM solucion_ejercicio_109;

-- 110. Obtener para cada empleado su código, su nombre, el código y el nombre de su supervisor, y el número de 
-- empleados que supervisa su supervisor. Propón tres alternativas de solución.
-- Alternativa 1:
select e1.empno, e1.ename, e2.empno sup, e2.ename sup_name, e2.count
from emp e1
join (
	select es1.empno, es1.ename, COUNT(es2.empno) as count
	from emp es1
	join emp es2 ON es1.empno = es2.mgr
	group by es1.empno
) as e2 ON e1.mgr = e2.empno
order by e1.empno;

-- Alternativa 2:
select e1.empno, e1.ename, e2.empno sup, e2.ename sup_name, e2.count
from (
	select es1.empno, es1.ename, COUNT(es2.empno) as count
	from emp es1
	join emp es2 ON es1.empno = es2.mgr
	group by es1.empno
) as e2
join emp e1 ON e1.mgr = e2.empno
order by e1.empno;

-- Alternativa 3:
SELECT 
    e.empno,
    e.ename,
    s.empno AS mgr_empno,
    s.ename AS mgr_ename,
    COUNT(c.empno) AS num_supervised
FROM emp e
JOIN emp s ON e.mgr = s.empno
JOIN emp c ON c.mgr = s.empno
GROUP BY e.empno, e.ename, s.empno, s.ename
ORDER BY e.empno;

SELECT 
    e.empno,
    e.ename,
    s.empno AS mgr_empno,
    s.ename AS mgr_ename,
    (SELECT COUNT(*) FROM emp c WHERE c.mgr = s.empno) AS num_supervised
FROM emp e
JOIN emp s ON e.mgr = s.empno;

SELECT * FROM solucion_ejercicio_110 order by empno;

-- 111. Obtén el código, el nombre, el salario y la comisión de cada empleado, además de la situación en la que se 
-- encuentra cada empleado, entendiendo que los que tienen la comisión nula o el salario mayor que 1.400, están en el “Caso 
-- 1”, y los restantes están en el “Caso 2”.
select 
	empno,
	ename,
	sal,
	comm,
	CASE
		WHEN sal > 1400 OR comm IS NULL THEN 'CASO 1'
		ELSE 'CASO 2'
	END caso
FROM emp;

SELECT * FROM solucion_ejercicio_111;

-- 112. Entendiendo que la retribución total es la suma del salario más la comisión, obtén los datos de los empleados 
-- cuya retribución total es mayor que 1700.
SELECT sal + COALESCE(comm, 0) retrib FROM emp WHERE sal + COALESCE(comm, 0) > 1700;

SELECT * FROM solucion_ejercicio_112;

-- 113. Obtén la media del salario de cada departamento si el salario mínimo fuese 2000, esto es, si a los empleados 
-- cuyo salario fuese menor, se les contabilizase como salario el valor de 2000.
select 
	deptno,
    AVG(CASE WHEN sal < 2000 THEN 2000 ELSE sal END) AS avg_salary
from emp
group by deptno;

SELECT * FROM solucion_ejercicio_113;

-- 114. Obtén el código, nombre, salario y comisión de los empleados, ordenando por la comisión, en orden ascendente.
select empno, ename, sal, comm
from emp
order by comm asc;

SELECT * FROM solucion_ejercicio_114;

-- 115. El ejercicio anterior obteniendo ahora un orden descendente de comisión.
select empno, ename, sal, comm
from emp
order by comm desc;

SELECT * FROM solucion_ejercicio_115;


-- 116. Obtén el código, nombre, salario y comisión de los empleados, con los valores de comisión ordenados de 
-- forma ascendente, pero con los valores no nulos primero. Hazlo de dos formas distintas.
-- Alternativa 1:
SELECT empno, ename, sal, comm
FROM emp
ORDER BY 
    CASE WHEN comm IS NULL THEN 1 ELSE 0 END,
    comm ASC;

-- Alternativa 2:
SELECT empno, ename, sal, comm
FROM emp
ORDER BY 
	ISNULL(comm),
	comm;

SELECT * FROM solucion_ejercicio_116;

-- 117. Obtén los datos de todos los empleados (código, nombre y salario) de forma que, si además un empleado está 
-- vinculado a algún proyecto, aparezca el código del proyecto y las horas que le dedica, pero solo para los proyectos a 
-- los que le dedica más de diez horas. Ordena por el nombre de empleado y por el código del proyecto.
select e.empno, ename, sal, prono, hours
from emp e
left join emppro ep ON e.empno = ep.empno AND hours > 10
order by ename, prono;

SELECT * FROM solucion_ejercicio_117;

-- 118. Obtén el nombre del departamento que posee la mayor media de los salarios de los empleados y el valor de esa 
-- media utilizando operadores cuantificados (ALL, ANY); luego hazlo de nuevo, pero sin usar operadores cuantificados 
-- y finalmente hazlo, pero sin utilizar ningún join.
-- Alternativa 1 (con operadores cuantificados):
select dname, avg(sal) as avg_sal
from dept
natural join emp
group  by dname
having avg_sal >= all (select avg(sal) from emp group by deptno);

-- Alternativa 2 (sin operadores cuantificados):
select dname, avg(sal) as avg_sal
from dept
natural join emp
group  by dname
order by avg_sal desc limit 1;

SELECT dname, avg_sal
FROM (
    SELECT 
        d.dname,
        AVG(e.sal)         AS avg_sal,
        MAX(AVG(e.sal)) OVER () AS max_avg
    FROM emp e
    JOIN dept d ON e.deptno = d.deptno
    GROUP BY d.dname, d.deptno
)
WHERE avg_sal = max_avg;

-- Alternativa 3 (sin utilizar ningún join):
SELECT 
    (SELECT dname FROM dept WHERE deptno = e.deptno) AS dname,
    AVG(e.sal) AS avg_sal
FROM emp e
GROUP BY e.deptno
order by avg_sal desc limit 1;

SELECT * FROM solucion_ejercicio_118;

-- 119. Obtén el código y el nombre del departamento que posee la mayor media de los salarios de los empleados, el valor 
-- de esa media y el número de proyectos en los que trabajan los empleados que pertenecen a ese departamento.
select d.dname, COALESCE(avg(e.sal),0) avg_sal, count(DISTINCT ep.prono)
from dept d
natural left join emp e
natural left join emppro ep
group by d.deptno, d.dname
order by avg_sal desc limit 1;

SELECT * FROM solucion_ejercicio_119;

-- 120. Obtén el empleado con el tercer salario más alto, o el cuarto, etc.
SELECT *
FROM (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY sal desc) AS rnk
    FROM emp
) as s
WHERE rnk = 3;

SELECT *
FROM emp e
WHERE 2 = (
    SELECT COUNT(DISTINCT sal)
    FROM emp
    WHERE sal > e.sal
);

SELECT *
FROM emp
ORDER BY sal DESC
LIMIT 1 OFFSET 3;

SELECT * FROM solucion_ejercicio_120;

-- 121. Obteén los empleados con los dos salarios más altos, o con los cuatro, etc.
SELECT *
FROM (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY sal desc) AS rnk
    FROM emp
) as s
WHERE rnk < 5;

SELECT *
FROM emp e
WHERE (
    SELECT COUNT(DISTINCT sal)
    FROM emp
    WHERE sal > e.sal
) between 1 and 3;

SELECT *
FROM emp
ORDER BY sal DESC
LIMIT 5;

SELECT * FROM solucion_ejercicio_121;

-- EXTRA (TEÓRICOS):

-- 122. Discute los parecidos y las diferencias entre (NATURAL JOIN) y (JOIN con USING).
-- Natural join allows the user to not specify column that will be used to join two tables. 'using' allows
-- the programmer to specify what column (that both tables have) will be used for the join.

-- 123. Obtén los códigos, nombres y salarios de los empleados vinculados a algún proyecto, además de obtener el código 
-- y el nombre del proyecto, y el número de horas. Realízalo usando primero joins normales y utilizando luego natural 
-- joins. Observa si se producen diferencias y, en su caso, explícalas.
-- Natural joins join tables by all the commun column names, since pro table has columns deptno and prono joins are made
-- with these two columns which leads to errors.
select empno, ename, sal, prono, pname, hours
from emp
join emppro using (empno)
join pro using (prono);

select empno, ename, sal, p.prono, pname, hours
from emp
natural join emppro ep
join pro p on p.prono = ep.prono;

select empno, ename, sal, prono, pname, hours
from emp
natural join emppro 
natural join pro;

select empno, ename, sal, p.prono, pname, hours
from emp e
natural join emppro ep
join pro p on p.prono = ep.prono AND p.deptno = e.deptno;