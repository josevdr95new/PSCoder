# 30 Tareas Complejas para Pruebas de IA - PSCoder + OrcaRouter
# ============================================================
# Configurar: /provider orca
# Modelo: /model z-ai/glm-5.3-flash-free
# API: https://api.orcarouter.ai/v1/chat/completions
# ============================================================

## CATEGORÍA 1: Razonamiento Lógico (1-6)

1. "Tres personas (Ana, Beto, Carla) tienen profesiones diferentes (médico, abogado, ingeniero). Ana no es médico. Beto no es abogado. Carla no es ingeniero ni médico. El abogado vive al lado del ingeniero. ¿Quién es cada profesión? Explica paso a paso."

2. "Tienes 8 bolas idénticas en apariencia, una pesa más. Tienes una balanza de dos platos. ¿Cuál es el MÍNIMO de pesadas para encontrar la más pesada? Demuestra que no se puede hacer en menos."

3. "Un tren sale de La Habana a Santiago a 80 km/h. Otro sale de Santiago a La Habana a 120 km/h. Distancia: 900 km. ¿En cuánto tiempo se cruzan? ¿A qué distancia de La Habana?"

4. "Escribe una función PowerShell que reciba un array de números y devuelva: media, mediana, moda, desviación estándar y rango. Maneja arrays vacíos y duplicados."

5. "Matriz 3x3 con números del 1 al 9, suma de cada fila/columna/diagonal = 15. ¿Cuántas formas hay? Lista las soluciones."

6. "Un granjero tiene 100m de cerca y quiere encerrar un área rectangular junto a un río (un lado es el río). ¿Dimensiones que maximizan el área? Usa cálculo diferencial."

## CATEGORÍA 2: Programación (7-12)

7. "Script PowerShell que monitoree un directorio y detecte archivos nuevos/modificados/eliminados en tiempo real. Registra cambios en CSV."

8. "Crea clase PowerShell 'NetworkMonitor': ping concurrente a múltiples hosts, registra latencia promedio, detecta desconexiones, genera reporte HTML."

9. "Implementa merge sort en PowerShell. Maneja arrays de cualquier tipo, comparador personalizado, muestra número de comparaciones."

10. "Función recursiva Fibonacci con memoización en PowerShell. Compara rendimiento con/sin memoización para n=40."

11. "Script que lee JSON con servidores (nombre, IP, puerto), hace test TCP a cada uno, genera reporte con tiempo de respuesta y recomendaciones."

12. "Patrón Observer en PowerShell: clase Subject notifica a múltiples observers. Úsalo para sistema de alertas con 3 servicios."

## CATEGORÍA 3: Análisis de Datos (13-18)

13. "Dado CSV con: fecha, provincia, velocidad_mbps, operador — agrupa por provincia, calcula promedio/máx/mín, identifica outliers (>2 desv. estándar)."

14. "Extrae del texto: entidades, fechas, cantidades, lugares. Texto: 'El 15 de marzo de 2026, TechCorp lanzó CloudX 3.0 en Madrid, precio 299 euros, soporta 10,000 usuarios.'"

15. "Genera datos sintéticos de velocidad de internet para 16 provincias de Cuba durante 30 días, con variaciones realistas, exporta a CSV."

16. "Algoritmo que detecte anomalías en serie temporal de latencia de red usando Z-score con ventana móvil de 10."

17. "Dado logs de red (timestamp, IP origen/destino, bytes, protocolo) — detecta: escaneo de puertos, transferencias anómalas, conexiones sospechosas."

18. "Función que compara dos CSV por columna clave, genera diff: filas añadidas/eliminadas/modificadas con valor anterior y nuevo."

## CATEGORÍA 4: Agentes Autónomos (19-24)

19. "Agente DevOps: revisa el directorio actual, identifica proyecto git, analiza últimos 5 commits, sugiere 3 mejoras de workflow."

20. "Agente de seguridad: escanea directorio buscando credenciales hardcodeadas, permisos excesivos, comandos peligrosos. Genera reporte."

21. "Code review: lee el archivo .ps1 más reciente, analiza bugs, malas prácticas, código duplicado. Sugiere refactorizaciones."

22. "Agente documentación: lee todos los .ps1 del directorio, extrae funciones públicas, genera README.md con tabla de funciones y ejemplos."

23. "Troubleshooting: simula servicio web en puerto 8080 que no responde. Crea plan de diagnóstico, ejecuta comandos, propón soluciones."

24. "Optimización: implementa 3 algoritmos de búsqueda (lineal, binaria, hash) en PowerShell, mide tiempo con Measure-Command para 1K/10K/100K elementos."

## CATEGORÍA 5: Creatividad y Multi-step (25-30)

25. "Diseña arquitectura para app de monitoreo de red móvil: componentes, APIs, DB, flujo de datos. Diagrama ASCII incluido."

26. "Cuento ciencia ficción 500 palabras: IA que descubre que siente dolor. Introducción, nudo, desenlace, twist final."

27. "Curso PowerShell de 5 lecciones para principiantes: objetivos, teoría, 3 ejercicios progresivos, proyecto final."

28. "Debate entre 3 expertos (arquitecto, sysadmin, CTO) sobre migrar de monolito a microservicios. 3 argumentos a favor y 3 en contra cada uno."

29. "Plan de negocios para startup de monitoreo de red en Cuba: análisis de mercado, modelo de ingresos, proyección 12 meses, costos."

30. "Protocolo de comunicación para enjambre de 5 robots exploradores: mensajes, prioridades, manejo de conflictos, algoritmo de consenso."

## CRITERIOS DE EVALUACIÓN (1-10)

| Puntuación | Descripción |
|-----------|-------------|
| 1-2 | Respuesta incoherente o no respondió la pregunta |
| 3-4 | Intentó responder pero con errores graves o incompleto |
| 5-6 | Respuesta correcta pero superficial, sin profundidad |
| 7-8 | Respuesta buena, con detalles y razonamiento adecuado |
| 9 | Excelente, creativo, con insights adicionales |
| 10 | Perfecto, mejor de lo esperado, código ejecutable verificado |
