-- ##########################################################
-- #  NOTA: utiliza la base de datos basic_employees	 	#
-- #  (esquema disponible en Esquemas/basic_employees.png)  #
-- ##########################################################

use basic_employees;

-- 1. Obtén el código, nombre, salario y número de orden del salario de los empleados, de mayor a menor.
select empno, ename, sal,
	dense_rank() over (order by sal desc) as orden
from emp;

-- 2. Obtén los empleados con el segundo salario más alto, usando funciones de ventana.
select empno, ename, sal, orden
from (
	select *,
		rank() over (order by sal desc) as orden
	from emp
) as e
where orden = 2;

-- hola hola esto se deberia ignorae
delete from emp; -- esto tambien se deberia ignorar

-- 3. Obtén los empleados con los cinco salarios más altos, usando funciones de ventana.
select empno, ename, sal, orden
from ( -- comentario en linea
	select *,
		dense_rank() over (order by sal desc) as orden
	from emp
) as e
where orden < 6;

-- ignore

select * from emp;
select * from devoluciones;

-- hello

-- 4. Obtén los empleados cuyo salario está en un rango de posiciones, por ejemplo, entre los terceros y 
-- los octavos más altos, usando funciones de ventana.
select empno, ename, sal, orden
from (
	select *,
		dense_rank() over (order by sal desc) as orden
	from emp
) as e
where orden between 3 and 8;

-- 5. Obtén los empleados cuyo salario supera al de sus compañeros de departamento. Si hay algún departamento donde 
-- dos, o más, empleados tienen el salario más alto, entonces nadie supera a sus compañeros.
SELECT empno, deptno, sal, orden
FROM (
    SELECT empno, deptno, sal,
           RANK()  OVER (PARTITION BY deptno ORDER BY sal DESC) AS orden,
           COUNT(*) OVER (PARTITION BY deptno, sal) AS same_sal_count
    FROM emp
) as t
WHERE orden = 1 AND same_sal_count = 1;

with sub as (
	select
		empno,
		deptno,
		sal, 
		RANK() OVER (PARTITION BY deptno ORDER BY sal DESC) AS orden
    FROM emp
)
SELECT empno, deptno, sal, orden
FROM sub s
WHERE orden = 1 AND 1 = (
	select COUNT(*)
	from sub ss
	where ss.deptno = s.deptno AND orden = 1
	group by deptno
);

-- ##########################################################
-- #  NOTA: utiliza la base de datos wf	 	   				#
-- #  (esquema disponible en Esquemas/wf.png)  				#
-- ##########################################################
use wf;

-- 6. En las tablas pedidos y devoluciones, se almacena información referente a pedidos y devoluciones de una compañía.
-- Cada pedido se identifica a través de la columna id_pedido y cada devolución a través de id_devolucion. Cada devolución
-- está asociada a un pedido a través de la columna id_pedido de la tabla devoluciones. Obtén los pedidos que más unidades
-- han devuelto, las unidades de vueltas y el ranking en base a las unidades devueltas.
with s as (
	select id_pedido, sum(unidades) as unidades_devueltas
	from devoluciones
	group by id_pedido
)
select *
from (
	select *,
		rank() over(order by unidades_devueltas desc) as orden
	from s
) as s;