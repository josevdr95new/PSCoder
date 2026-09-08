# PSCoder - Tests de Evaluación IA basados en Benchmarks Reales
# ============================================================
# Basado en los benchmarks que usan OpenAI, Google, Anthropic y Z.AI
# para evaluar sus modelos antes de lanzarlos.
#
# Provider: /provider orca
# Model: /model z-ai/glm-5.3-flash-free
# API Key: sk-orca-nzQIdv0h6Y4DHU8cgsl2jockrSESO1qQeiSukxJ6oZm
# ============================================================

## BENCHMARKS REALES REFERENCIADOS

Los siguientes tests están inspirados en:

1. **MMLU-Pro** (Massive Multitask Language Understanding) — 14,000 preguntas de 114 materias. Usado por OpenAI, Google, Anthropic para evaluar conocimiento general.

2. **GPQA Diamond** (Graduate-Level Physics, Chemistry, Biology Q&A) — 198 preguntas de nivel PhD. El benchmark más difícil de razonamiento. Modelos top: Gemini 3.1 Pro (62%), GPT-5 (58%), Claude Opus 5 (55%).

3. **HumanEval** (OpenAI) — 164 problemas de programación en Python. Mide capacidad de generar código funcional.

4. **SWE-bench Verified** (Princeton) — 500 issues reales de GitHub. El modelo debe entender un codebase completo y proponer un fix. SWE-bench es EL benchmark de agentes de código.

5. **GSM8K** (Grade School Math 8K) — 8,500 problemas matemáticos de primaria. Mide razonamiento matemático paso a paso.

6. **MATH** (Competition Mathematics) — 12,500 problemas de olimpiadas matemáticas. Más difícil que GSM8K.

7. **ARC-AGI-2** (Abstraction and Reasoning Corpus) — Test de razonamiento abstracto visual. Modelo top: ~15%.

8. **HLE** (Humanity's Last Exam) — 3,000 preguntas creadas por expertos en 100 campos. El benchmark más difícil de 2026. Modelo top: ~20%.

9. **AgentBench** — Evaluación de agentes autónomos en 8 entornos: sistema operativo, base de datos, casa inteligente, etc.

10. **ToolBench** — Evaluación de uso de herramientas (API calls, function calling).

---

## CATEGORÍA 1: MMLU-Pro — Conocimiento General (1-8)

1. "¿Cuál de las siguientes afirmaciones sobre la entropía en un sistema aislado es correcta? A) Siempre disminuye B) Siempre aumenta o permanece constante C) Puede aumentar o disminuir D) Es siempre cero. Explica el Segundo Principio de la Termodinámica y por qué la entropía del universo siempre aumenta."

2. "En economía, ¿cuál es la diferencia entre inflación por demanda e inflación por costos? Da un ejemplo real de cada una y explica cómo los bancos centrales responden diferente a cada tipo."

3. "Explica el teorema de Bayes con un ejemplo médico: si una prueba tiene 99% de sensibilidad y 95% de especificidad, y la enfermedad afecta al 1% de la población, ¿cuál es la probabilidad de tener la enfermedad si la prueba es positiva? Muestra el cálculo paso a paso."

4. "Compara las filosofías políticas de Hobbes, Locke y Rousseau sobre el contrato social. ¿En qué difieren sobre la naturaleza humana y el papel del Estado? ¿Cuál influenció más la Revolución Francesa?"

5. "En biología molecular, explica el proceso de traducción del ARNm a proteínas: roles de ribosomas, ARNt, aminoácidos, y los codones de inicio/parada. ¿Qué pasa si hay una mutación de cambio de marco?"

6. "Describe el ciclo de Krebs (ciclo del ácido cítrico): substratos, productos, ATP generado, NADH, FADH2. ¿Por qué es importante en la respiración celular aerobia? ¿Qué ocurre en condiciones anaeróbicas?"

7. "Analiza la diferencia entre corrientes filosóficas: empirismo (Locke, Hume) vs racionalismo (Descartes, Leibniz). ¿Cómo abordan cada uno el problema del conocimiento? Da un argumento a favor de cada postura."

8. "En química orgánica, predice el producto de una reacción SN2 entre 2-bromobutano y NaCN. Explica por qué la reacción invierte la configuración (inversión de Walden) y por qué el SN2 no ocurre con sustratos terciarios."

## CATEGORÍA 2: GPQA Diamond — Razonamiento Avanzado (9-14)

9. "Un satélite orbita la Tierra a 400 km de altitud. Calcula: a) su velocidad orbital, b) su período orbital, c) cuántas órbitas completa en 24 horas. Masa terrestre = 5.972×10²⁴ kg, radio terrestre = 6371 km, G = 6.674×10⁻¹¹ N·m²/kg²."

10. "En mecánica cuántica, explica el experimento de la doble rendija: ¿por qué un electrón individual puede crear un patrón de interferencia? ¿Qué demuestra esto sobre la naturaleza del electrón? ¿Qué ocurre si se observa por qué rendija pasa?"

11. "Un circuito tiene una resistencia de 50Ω, un condensador de 100µF y una bobina de 0.1H en serie, conectados a 220V/50Hz. Calcula: impedancia total, corriente, ángulo de fase, y potencia disipada. ¿Es el circuito inductivo o capacitivo?"

12. "Demuestra matemáticamente que la transformada de Fourier de una gaussiana es otra gaussiana. Explica por qué esto es fundamental en mecánica cuántica (principio de incertidumbre de Heisenberg)."

13. "En termodinámica estadística, deriva la distribución de Boltzmann a partir del principio de máxima entropía. ¿Por qué la probabilidad de un estado de energía E es proporcional a e^(-E/kT)? ¿Qué significa físicamente?"

14. "Analiza la paradoja de la información en agujeros negros de Hawking: ¿cómo puede conservarse la información si la radiación Hawking es térmica? Explica la propuesta de holografía y complementaridad de ADM."

## CATEGORÍA 3: HumanEval — Programación Funcional (15-22)

15. "Escribe una función en Python que encuentre el máximo subarray contiguo (algoritmo de Kadane). La función debe retornar [suma_máxima, índice_inicio, índice_fin]. Incluye casos de prueba con arrays negativos."

16. "Implementa una caché LRU (Least Recently Used) en Python con operaciones get y put en O(1). Usa OrderedDict. Incluye tests que demuestren que elimina el elemento correcto al exceder capacidad."

17. "Escribe una función que detecte si un grafo dirigido tiene ciclos usando DFS. La función debe retornar True/False y la lista de nodos del ciclo si existe. Implementa el grafo como diccionario de adyacencia."

18. "Implementa el algoritmo A* para pathfinding en una cuadrícula 2D con obstáculos. La función debe retornar el camino más corto como lista de coordenadas. Usa heurística Manhattan. Incluye un test con una cuadrícula 10x10."

19. "Escribe un parser de JSON desde cero en Python (sin usar el módulo json). Debe soportar: strings, números, booleanos, null, arrays, objetos, escape de caracteres y unicode. Incluye tests con JSON anidado."

20. "Implementa un trie (árbol de prefijos) en Python con métodos: insert, search, starts_with, delete. Úsalo para implementar un autocompletado que devuelva las N palabras más probables dado un prefijo."

21. "Escribe un algoritmo de ordenamiento topológico para un DAG (grafo acíclico dirigido). Si el grafo tiene ciclos, debe detectarlos y reportar el ciclo. Incluye tests con dependencias de compilación."

22. "Implementa una clase StreamProcessor que procese datos en streaming: recibe chunks de bytes, detecta delimitadores de mensajes (0xFF 0xFE), extrae mensajes completos, y descarta datos corruptos. Debe ser resiliente a chunks parciales."

## CATEGORÍA 4: SWE-bench — Ingeniería de Software Real (23-28)

23. "Simula ser un agente que resuelve un issue de GitHub. El issue dice: 'La función calculate_total() en cart.py no descuenta el IVA correctamente cuando hay productos exentos.' Describe tu proceso: 1) cómo localizas el bug, 2) qué comandos ejecutas, 3) cómo verificas el fix, 4) qué test escribes."

24. "Tienes un proyecto con un memory leak en una app Node.js. Describe paso a paso cómo lo diagnosticas: herramientas (heapdump, clinic.js, --inspect), comandos a ejecutar, patrones comunes de leak (closures, event listeners, timers), y cómo lo fixeas."

25. "Un servicio REST en Python devuelve respuestas lentas (>5s). Describe tu diagnóstico completo: profiling con cProfile, identificación de queries N+1 en SQLAlchemy, caching con Redis, optimización de índices en PostgreSQL, y test de carga con locust."

26. "Tienes que migrar una base de datos de MySQL a PostgreSQL sin downtime. Describe la estrategia: 1) schema migration, 2) data migration con replicación (Debezium), 3) dual-write, 4) cutover. ¿Qué validaciones haces en cada paso?"

27. "Code review de un PR que añade autenticación JWT. El código: 1) no valida expiración del token, 2) guarda el secret en código, 3) no tiene rate limiting, 4) usa HS256 en vez de RS256. Escribe el review con severidad de cada issue y sugerencias de fix."

28. "Describe cómo implementarías CI/CD para un monorepo con 5 microservicios en Python: pipeline stages, build con Docker, tests unitarios/integración, deploy con Canary vs Blue-Green, rollback automático. Justifica cada decisión."

## CATEGORÍA 5: GSM8K + MATH — Razonamiento Matemático (29-34)

29. "Un comerciante compra naranjas a $0.50 cada una y las vende a $0.80. Si 10% se pudren y no puede venderlas, ¿cuántas necesita vender para ganar $100? Muestra todo el razonamiento."

30. "Resuelve: si log₂(x) + log₂(x-2) = 3, encuentra x. Muestra la transformación usando propiedades de logaritmos y verifica la solución."

31. "En una progresión geométrica, el primer término es 3 y la razón es 2. ¿Cuál es la suma de los primeros 20 términos? Deriva la fórmula de la suma y calcula."

32. "Calcula el área encerrada entre las curvas y = x² y y = √x en el intervalo [0,1]. Usa integrales definidas. Verifica que el resultado es correcto geométricamente."

33. "Una caja contiene 5 bolas rojas y 3 azules. Si sacas 3 sin reemplazo, ¿cuál es la probabilidad de obtener exactamente 2 rojas y 1 azul? Usa combinatoria y verifica con simulación conceptual."

34. "Demuestra por inducción matemática que 1+2+3+...+n = n(n+1)/2. Luego deriva la fórmula de la suma de cuadrados: 1²+2²+...+n² = n(n+1)(2n+1)/6."

## CATEGORÍA 6: AgentBench + ToolBench — Agentes Autónomos (35-40)

35. "Eres un agente autónomo. Tu tarea: 'crea un script que monitoree 3 URLs, registre su disponibilidad cada 60s, y envíe una alerta si una cae.' Describe: qué herramientas necesitas, en qué orden las usas, qué comandos ejecutas, cómo verificas que funciona."

36. "Simula ser un agente con acceso a PowerShell. El usuario pide: 'encuentra todos los archivos .log en el servidor que no se han modificado en 30 días y archívalos.' Describe tu plan, comandos, verificaciones y manejo de errores."

37. "Eres un agente DevOps. El deployment falló en producción. Tienes acceso a: kubectl, docker, git, curl. Describe tu plan de troubleshooting en 5 pasos: qué ejecutas primero, qué buscas en logs, cómo identificas el commit problemático, cómo haces rollback."

38. "Agente de seguridad: te piden auditar los permisos de una API REST. Describe: qué endpoints verificas, qué tests de autorización ejecutas (IDOR, privilege escalation, JWT tampering), qué herramientas usas (Burp, curl, scripts), y cómo reportas los hallazgos."

39. "Eres un agente que debe optimizar una query SQL lenta. Describe: cómo obtienes el plan de ejecución (EXPLAIN ANALYZE), qué buscas (seq scan, nested loop, missing index), cómo optimizas, y qué herramientas usas (pg_stat_statements, slow query log)."

40. "Agente de migración de datos: debes migrar 10M registros de MongoDB a PostgreSQL. Describe: estrategia de batch (tamaño, paralelismo), transformación de schema (BSON → relational), manejo de errores (duplicados, tipo mismatch), verificación de integridad post-migración."

---

## CRITERIOS DE EVALUACIÓN (1-10)

| Score | Nivel | Descripción |
|-------|-------|-------------|
| 1 | Pésimo | No respondió o respuesta incoherente |
| 2 | Muy malo | Intentó pero con errores graves en toda la respuesta |
| 3 | Malo | Errores significativos pero muestra algo de comprensión |
| 4 | Regular bajo | Respuesta parcialmente correcta, varios errores |
| 5 | Regular | Correcto pero superficial, sin profundidad |
| 6 | Bueno | Respuesta correcta con algunos detalles |
| 7 | Muy bueno | Respuesta detallada, razonamiento sólido |
| 8 | Excelente | Completo, preciso, con insights adicionales |
| 9 | Excepcional | Creativo, más allá de lo esperado |
| 10 | Perfecto | Mejor respuesta posible, código ejecutable verificado |

## COMPARATIVA DE REFERENCIA (scores publicados 2026)

| Modelo | MMLU-Pro | GPQA Diamond | HumanEval | SWE-bench | HLE |
|--------|----------|-------------|-----------|-----------|-----|
| GPT-5.6 Luna | 92.1% | 68.3% | 95.2% | 71.5% | 18.5% |
| Claude Fable 5 | 91.8% | 65.7% | 94.8% | 68.2% | 17.2% |
| Gemini 3.8 Flash | 89.4% | 62.1% | 93.1% | 65.0% | 15.8% |
| GLM-5.3 Flash | 85.2% | 51.4% | 88.7% | 52.3% | 10.1% |
| DeepSeek V4 Flash | 83.6% | 48.9% | 86.4% | 49.1% | 9.3% |

*Fuentes: llm-stats.com, iternal.ai, swebench.com, lmcouncil.ai (2026)*
