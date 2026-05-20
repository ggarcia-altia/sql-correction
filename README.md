# Script the corrección de ejercicios de SQL

## 📒 Sobre el script
Este script sirve para corregir los ejercicios de sql de los boletines 1 y 3 del datacamp de Altia. Los boletines 1 y 2 no se pueden corregir porque no tienen soluciones.

## 🔧 Funcionamiento
Este script realiza las siguientes fases:

1. Obtiene las soluciones de los ejercicios del usuario: se analiza el archivo con las soluciones del usuario línea a línea. En cada línea, mediante expresiones regulares, se analiza si esa línea tiene contenido que se puede ignorar (comentarios, líneas en blanco o sentencias de SQL que no son soluciones a ejercicios) o contenido importante (soluciones a ejercicios o enunciados de ejercicios). Una vez hecho esto se obtienen todas las soluciones a los ejercicios de los usuarios agrupadas por ejercicios.
1. Ejecución y comprobación de las soluciones: una vez obtenidas las soluciones se ejecutan y comprueban que su resultado es el esperado. Aquellos ejercicios para los cuales no existe una solución se ignoran.
1. Muestra de resultados: mostramos las correcciones a los alumnos.

## 🚦 Ejecución
Para ejecutar este script usando VS Code en Windows podemos seguir los siguientes pasos:
1. Instala python
1. Pulsando CTRL + shift + p, pulsa en la opción "Python: Create Environment", elige “.venv”  y selecciona un interpretador.
1. Abre la terminal de VS Code, deberías ver ".venv".
1. Instala dependencias con este comando:
    ```bash
    pip install sqlalchemy pandas pymysql rich
    ```

Una vez hecho todo esto podemos ejecutar el archivo. Para ello usamos este comando:
```bash
python check_queries.py tu_ruta_a_tu_boletin1.sql 1
```

Debes substituir la ruta de arriba con la ruta del boletín que quieres corregir. Además, debes indicar al final si el archivo son los ejercicios del boletín 1 o 3.
```bash
python check_queries.py tu_ruta_a_tu_boletin3.sql 3
```

Adicionalmente puedes seleccionar modo verbose donde se imprime todas las queries ejecutadas (puede ser útil para debuggear en caso de que creas que el script tiene bugs).
```bash
python check_queries.py -v tu_ruta_a_tu_boletin3.sql 3
```

## 📄 Formato de las soluciones
Para que un boletín se pueda corregir de forma correcta con este script este script se han de tener en cuenta las siguientes restricciones:

- Para que un ejercicio se corrija ha de estar debajo del enunciado del ejercicio. Como este script analiza las líneas una a una en orden, si se encuentra una sentencia de sql que comienza con with o select se asume que es una solución al último enunciado encontrado (si es que hay).
- Para que un ejercicio se corrija bien ha de tener el mismo número de columnas que la solución. Además, las columnas deben de estar en el mismo orden. Es decir, imaginemos que hay un ejercicio cuya solución devuelve las columnas name y age. Entonces esta solución no valdrá:
    ```sql
    select edad, nombre from …
    ```
        ya que el orden no es el correcto. Esta otra solución sí sería correcta:
    ```sql
    select nombre, edad from …
    ```
        Esta otra solución tampoco valdría por tener columnas de más:
    ```sql
    select nombre, edad, apellido from …
    ```
    Como se puede observar, las columnas no necesitan tener el mismo orden.
    Si una sentencia de sql no empieza con use, select o with se ignorará. Las sentencias use se tienen que usar para elegir la base de datos donde se ejecutará el ejercicio. Su uso es obligatorio ya que de ello depende que el script sepa en qué base de datos hay que ejecutar un ejercicio. Por ejemplo, si el ejercicio 13 se ejecuta en una base de datos distinta al ejercicio 12 y 14, habrá que incluir antes y después del ejercicio 13 las sentencias use adecuadas para esto.
- No se pueden escribir varias sentencias de sql en la misma línea, esto resultará en un comportamiento erróneo.
- No se pueden usar queries donde se usan variables definidas en otras sentencias:
    ```sql
    SELECT sal INTO @EmployeeSal FROM emp WHERE empno = 7934;
    SELECT * FROM emp WHERE sal > @EmployeeSal ORDER BY sal;
    ```


Sin embargo, tienes flexibilidad para:

- Añadir tus propios comentarios que se ignorarán: puedes añadir aclaraciones a tus consultas (ya sea en las misma líneas de la consulta o en otra distinta), comentar consultas enteras o modificar el enunciado de un ejercicio (siempre que no cambies el número del ejercicio).
- Puedes escribir varias soluciones para un ejercicio.
- Puedes dejar líneas en blanco entre soluciones o entre líneas de una solución.
- Puedes escribir las key words the sql en mayúsculas o minúsculas (`select` o `SELECT`, `use` o `USE`, `from` o `FROM` ...)
- Los resultados de tu query no han de tener el mismo orden que la solución.

Si en algún momento quieres que se ignoren consultas y no quieres tener que comentarlas todas puedes usar ```-- ignore``` o ```-- IGNORE```. Cuando se encuentre este comentario se ignorarán todas las consultas select o with que se encuentren entre este bloque y el próximo ejercicio. Ten en cuenta que las sentencias use no se ignorarán aunque estén después de un ignore.

## Ejemplos de archivos con formato correcto e incorrecto

Correcto ✅:
```sql
use basic_employees;
select ...; -- Esta query se ignorará al no haber un enunciado antes de ella

-- 1. Enunciado ejercico 1 bla bla (puedes cambiar el enuncado si quieres con tal de que no cambies el -- 1.)
-- Puedes añadir comentarios aquí, serán ignorados siempre que no empiecen por -- 1. o -- 2. ...
select ename  -- Puedes insertar un comentario aquí
from emp; -- Query del ejercicio 1
select ...; -- Otra query del ejercicio 1

-- 2. Enunciado ejercico 2 en base de datos jardinería
use jardineria;
select ...; -- Query del ejercicio 2
-- ignore
use basic_employees; -- Esta query no se ignorará
use basic_employees; -- No pasa nada si repites estas sentencias sin querer
select ...; -- Esta query se ignorará
-- 3. Enunciado ejercio 3 en basic employees bla bla
select ...; -- Solución del ejercico 3
-- 4. Enunciado ejercio 4 en basic employees bla bla
select ...; -- Solución del ejercico 4
with ...; -- Otra solución del ejercicio 4

-- 3.
select ...; -- Esta solución se considerará como otra solución del ejercicio 3 (aunque no tenga enunciado)
```

No correcto ❌:
```sql
use basic_employees;
-- 1. Enunciado ejercico 1 bla bla 
select ename from emp; select empno from emp; -- 🛑 No se admiten queries distintas en la misma línea

-- 2. Enunciado ejercico 2 en base de datos jardinería bla bla bla
use jardineria;
select age, name from ...; -- 🛑 Imaginemos que la solución tiene las columnas en el orden name y age, este ejercicio se corregería como incorrecto.

-- 3. Enunciado ejercio 3 en la base de datos basic_employees
-- 🛑 Aquí hay un error porque no se a puesto una sentencia USE para volver a cambiar a la base de datos basic_employees
select ...; -- Solución del ejercico 3
```