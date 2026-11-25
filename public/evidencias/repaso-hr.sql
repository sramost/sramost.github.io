-- Repaso posterior: esquema HR de Oracle. Solo consultas.
-- 6.1 Casos borde (el último conteo representa departamentos).
SELECT 'Sin jefe' caso_borde, COUNT(*) empleados_afectados,'manager_id nulo' descripcion FROM employees WHERE manager_id IS NULL
UNION ALL SELECT 'Sin departamento',COUNT(*),'department_id nulo' FROM employees WHERE department_id IS NULL
UNION ALL SELECT 'Sin comision',COUNT(*),'commission_pct nulo' FROM employees WHERE commission_pct IS NULL
UNION ALL SELECT 'Departamentos vacios',COUNT(*),'Conteo de departamentos, no empleados' FROM departments d WHERE NOT EXISTS(SELECT 1 FROM employees e WHERE e.department_id=d.department_id);
-- 6.2 COUNT(e.employee_id) ignora la fila artificial de la reunión externa.
SELECT d.department_id,d.department_name,l.city,c.country_name,COUNT(e.employee_id) employee_count,AVG(e.salary) avg_salary
FROM departments d LEFT JOIN locations l ON l.location_id=d.location_id LEFT JOIN countries c ON c.country_id=l.country_id LEFT JOIN employees e ON e.department_id=d.department_id
GROUP BY d.department_id,d.department_name,l.city,c.country_name;
-- 6.3 El self join externo conserva al empleado sin jefe.
SELECT e.employee_id,e.first_name||' '||e.last_name employee_name,j.job_title,e.manager_id,
CASE WHEN m.employee_id IS NOT NULL THEN m.first_name||' '||m.last_name END manager_name,d.department_name
FROM employees e LEFT JOIN employees m ON m.employee_id=e.manager_id JOIN jobs j ON j.job_id=e.job_id LEFT JOIN departments d ON d.department_id=e.department_id;
-- 6.4 ON conserva departamentos; WHERE descarta filas sin salario coincidente.
SELECT 'ON' variante,COUNT(*) filas_devueltas,'Conserva departamentos' explicacion FROM departments d LEFT JOIN employees e ON e.department_id=d.department_id AND e.salary>10000
UNION ALL SELECT 'WHERE',COUNT(*),'Descarta filas sin salario coincidente' FROM departments d LEFT JOIN employees e ON e.department_id=d.department_id WHERE e.salary>10000;
-- 6.5 NOT EXISTS no se contamina por los manager_id nulos.
SELECT e.employee_id,e.last_name,e.department_id,e.salary,e.commission_pct,e.salary*(1+NVL(e.commission_pct,0)) total_compensation,
CASE WHEN NOT EXISTS(SELECT 1 FROM employees x WHERE x.manager_id=e.employee_id) THEN 'NO' ELSE 'SI' END es_jefe FROM employees e;
SELECT employee_id FROM employees WHERE employee_id NOT IN(SELECT manager_id FROM employees);
-- 6.6 HAVING filtra grupos; CASE conserva el total general.
SELECT d.department_id,d.department_name,COUNT(*) employee_count,AVG(e.salary) avg_salary,MIN(e.salary) min_salary,MAX(e.salary) max_salary,SUM(e.salary) salary_mass,
COUNT(CASE WHEN e.hire_date>DATE '2005-01-01' THEN 1 END) empleados_recientes
FROM departments d JOIN employees e ON e.department_id=d.department_id GROUP BY d.department_id,d.department_name HAVING COUNT(*)>5 AND AVG(e.salary)>6000;
-- 6.7 Correlacion por department_id; empleados sin departamento quedan sin promedio.
WITH base AS (SELECT e.employee_id,e.last_name,e.department_id,e.salary,(SELECT AVG(x.salary) FROM employees x WHERE x.department_id=e.department_id) dept_avg_salary FROM employees e)
SELECT base.*,salary-dept_avg_salary diff_vs_avg,ROUND(100*(salary-dept_avg_salary)/NULLIF(dept_avg_salary,0),2) pct_vs_avg FROM base;
WITH promedios AS (SELECT department_id,AVG(salary) dept_avg_salary FROM employees GROUP BY department_id)
SELECT e.employee_id,e.last_name,e.department_id,e.salary,p.dept_avg_salary,e.salary-p.dept_avg_salary diff_vs_avg,ROUND(100*(e.salary-p.dept_avg_salary)/NULLIF(p.dept_avg_salary,0),2) pct_vs_avg
FROM employees e LEFT JOIN promedios p ON p.department_id=e.department_id;
-- Usar AUTOTRACE en SQL Developer para comparar ambas versiones; no hay planes medidos aquí.
-- 6.8 Los operadores de conjunto consideran iguales los NULL a efectos de duplicados.
WITH con_h AS (SELECT employee_id FROM employees INTERSECT SELECT employee_id FROM job_history),
sin_h AS (SELECT employee_id FROM employees MINUS SELECT employee_id FROM job_history),
estados AS (SELECT employee_id,'CON HISTORIAL' movilidad_status FROM con_h UNION ALL SELECT employee_id,'SIN HISTORIAL' FROM sin_h)
SELECT e.employee_id,e.last_name,s.movilidad_status FROM employees e JOIN estados s ON s.employee_id=e.employee_id;
SELECT e.employee_id,e.last_name,CASE WHEN NOT EXISTS(SELECT 1 FROM job_history j WHERE j.employee_id=e.employee_id) THEN 'SIN HISTORIAL' ELSE 'CON HISTORIAL' END movilidad_status FROM employees e;
-- 6.9 Oracle exige UNION ALL en la CTE recursiva; CYCLE detecta ciclos.
WITH jerarquia(employee_id,last_name,manager_id,nivel,ruta_jerarquica) AS (
SELECT employee_id,last_name,manager_id,1,CAST(last_name AS VARCHAR2(4000)) FROM employees WHERE manager_id IS NULL
UNION ALL SELECT e.employee_id,e.last_name,e.manager_id,j.nivel+1,CAST(j.ruta_jerarquica||' / '||e.last_name AS VARCHAR2(4000)) FROM employees e JOIN jerarquia j ON e.manager_id=j.employee_id
) CYCLE employee_id SET ciclo TO 'S' DEFAULT 'N'
SELECT employee_id,last_name,manager_id,nivel,ruta_jerarquica FROM jerarquia WHERE ciclo='N';
-- 6.10 RANK deja huecos; DENSE_RANK no; ROW_NUMBER distingue filas.
-- ROW_NUMBER sobre salarios empatados no garantiza orden individual; para LAG y acumulado usamos ID de desempate.
WITH b AS (
SELECT employee_id,last_name,department_id,salary,
ROW_NUMBER() OVER(PARTITION BY department_id ORDER BY salary DESC) rn,
RANK() OVER(PARTITION BY department_id ORDER BY salary DESC) rk,
DENSE_RANK() OVER(PARTITION BY department_id ORDER BY salary DESC) drk,
LAG(salary,1,salary) OVER(PARTITION BY department_id ORDER BY hire_date,employee_id) prev_salary,
SUM(salary) OVER(PARTITION BY department_id ORDER BY hire_date,employee_id ROWS UNBOUNDED PRECEDING) salary_running_total,
AVG(salary) OVER(PARTITION BY department_id) dept_avg_salary
FROM employees)
SELECT employee_id,last_name,department_id,salary,rn,rk,drk,prev_salary,salary-prev_salary delta_prev,salary_running_total,dept_avg_salary,ROUND(100*salary/NULLIF(dept_avg_salary,0),2) pct_vs_dept_avg FROM b;
-- Identificar empates reales; marco agregado por defecto con ORDER BY: RANGE UNBOUNDED PRECEDING.
SELECT department_id,salary,COUNT(*) cantidad FROM employees GROUP BY department_id,salary HAVING COUNT(*)>1;
-- 6.11 Se filtra el ranking en el nivel externo. Incluye empates.
WITH r AS (SELECT d.department_id,d.department_name,e.employee_id,e.last_name,e.salary,DENSE_RANK() OVER(PARTITION BY d.department_id ORDER BY e.salary DESC) drk FROM departments d JOIN employees e ON e.department_id=d.department_id)
SELECT * FROM r WHERE drk<=3 ORDER BY department_id,drk,employee_id;
-- 6.12 I.1 COUNT(*) contaba filas artificiales.
SELECT d.department_name,COUNT(e.employee_id) FROM departments d LEFT JOIN employees e ON d.department_id=e.department_id GROUP BY d.department_id,d.department_name;
-- I.2 NOT IN excluye NULL; se incluye a quienes no tienen departamento.
SELECT last_name FROM employees WHERE department_id NOT IN(10,20,30) OR department_id IS NULL;
-- I.3 Conteo de empleados reales; el filtro de país sí debe restringir departamentos.
SELECT d.department_name,COUNT(e.employee_id) FROM departments d JOIN locations l ON d.location_id=l.location_id LEFT JOIN employees e ON d.department_id=e.department_id WHERE l.country_id='US' GROUP BY d.department_id,d.department_name;
-- I.4 Agrupar por apellido no identifica el máximo por departamento.
WITH r AS (SELECT department_id,last_name,salary,DENSE_RANK() OVER(PARTITION BY department_id ORDER BY salary DESC) drk FROM employees WHERE department_id IS NOT NULL)
SELECT department_id,last_name,salary FROM r WHERE drk=1;
-- I.5 AVG ignora NULL: reemplazar por cero antes de agregar.
SELECT AVG(NVL(commission_pct,0)) FROM employees;
-- Todas las salidas y planes están pendientes de ejecución en Oracle.
