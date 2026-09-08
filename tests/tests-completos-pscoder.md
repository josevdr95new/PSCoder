# PSCoder - Tests Completos de TODAS las Funcionalidades
# ============================================================
# Este archivo prueba cada capacidad de PSCoder:
# - 8 Skills (code-generation, data-extraction, debug, docs, file-analysis, ps-admin, refactor, web-research)
# - 20 Herramientas (tools) registradas en ToolRegistry
# - 5 Sistemas Core (AutoHealing, AutoImprove, MemoryDecision, Hooks, ReasoningEngine)
# - 3 Providers (OpenRouter, Groq, OrcaRouter)
# - Slash commands (/help, /model, /provider, /memory, /config, /narrate, /tools)
#
# Provider: /provider orca
# Model: /model z-ai/glm-5.3-flash-free
# ============================================================

## ============================================================
## SECCIÓN A: SLASH COMMANDS BÁSICOS (1-6)
## ============================================================

1. "/help — Ejecuta /help y verifica que muestra todos los comandos disponibles: /clear, /model, /provider, /memory, /tools, /config, /narrate, /speak, /pwd, /exit. ¿Están todos listados?"

2. "/tools — Ejecuta /tools y verifica que lista las 20 herramientas: execute_powershell, read_file, write_file, edit_file, search_files, glob_files, list_directory, get_current_dir, web_search, web_fetch, auto_heal, learn_from_error, find_solution, ocr_image, create_plan, verify_step, verify_task, save_learning, list_skills, read_skill, add_plan_step."

3. "/model — Ejecuta /model sin argumentos y verifica que muestra modelos de OpenRouter, Groq Y OrcaRouter (incluyendo los modelos -free)."

4. "/provider — Ejecuta /provider sin argumentos. Debe mostrar: openrouter, groq, orca. Luego ejecuta /provider orca y verifica que cambia el provider y el modelo a z-ai/glm-5.3-flash-free."

5. "/config — Ejecuta /config y verifica que muestra todas las claves de configuración: apiKey, groqApiKey, orcaApiKey, provider, model, orcaModel, maxTokens, temperature, etc. Luego ejecuta /config temperature 0.5 y verifica que se actualiza."

6. "/memory add prueba — Ejecuta /memory add 'Esto es una prueba de memoria'. Luego ejecuta /memory y verifica que aparece la nota. Luego /memory clear para limpiar."

## ============================================================
## SECCIÓN B: SKILLS — Sistema de Habilidades (7-14)
## ============================================================

### Skill: code-generation
7. "Necesito que generes un script de PowerShell que monitoree el uso de CPU y memoria cada 5 segundos, y genere una alerta si la CPU supera el 80%. Usa el skill de code-generation."

### Skill: data-extraction
8. "Extrae todos los datos del siguiente texto y estructúralos en formato tabla: 'El servidor SRV-01 con IP 192.168.1.10 tiene 8GB RAM, CPU Intel Xeon E5, disco 500GB SSD, Windows Server 2019. El servidor SRV-02 con IP 192.168.1.11 tiene 16GB RAM, CPU AMD EPYC, disco 1TB NVMe, Ubuntu 22.04.'"

### Skill: debug-error
9. "Tengo este error en PowerShell: 'Cannot bind argument to parameter Path because it is null. At line:5 char:15 + Get-Content $file <<<<'. ¿Cómo lo resuelvo? Usa el skill de debug."

### Skill: documentation
10. "Genera documentación completa para esta función PowerShell: function Get-SystemInfo { param([string]$ComputerName='localhost') Get-CimInstance Win32_ComputerSystem -ComputerName $ComputerName | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory }. Crea un README.md con descripción, parámetros, ejemplos y requisitos."

### Skill: file-analysis
11. "Analiza la estructura del directorio actual. Lista todos los archivos .ps1, identifica los módulos principales, detecta dependencias entre archivos (quién importa a quién), y genera un árbol de dependencias."

### Skill: powershell-admin
12. "Como administrador del sistema, necesito: 1) listar los 10 procesos que más CPU consumen, 2) verificar el espacio en disco de todas las unidades, 3) mostrar los servicios que están configurados para iniciar automáticamente pero están detenidos. Usa el skill de powershell-admin."

### Skill: refactor
13. "Refactoriza este código PowerShell para que sea más eficiente y legible: `$r = @(); foreach ($i in 1..100) { $r += Get-Random }; return $r. Sugiere mejoras: usar pipeline, medir rendimiento, explicar por qué es mejor."

### Skill: web-research
14. "Busca en internet cuál es la última versión de PowerShell y cuáles son las novedades principales. Usa el skill de web-research y la herramienta web_search."

## ============================================================
## SECCIÓN C: HERRAMIENTAS (TOOLS) — Cada tool individual (15-30)
## ============================================================

### execute_powershell
15. "Ejecuta este comando de PowerShell: Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, WorkingSet. Muestra los 5 procesos que más CPU consumen."

16. "Ejecuta: Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}, @{N='Free(GB)';E={[math]::Round($_.FreeSpace/1GB,2)}}. Muestra el espacio en disco."

### read_file + write_file
17. "Crea un archivo llamado test-pscoder.txt con el contenido 'Hola desde PSCoder'. Luego léelo y muéstrame el contenido para verificar que se creó correctamente."

### edit_file
18. "Crea un archivo config-test.txt con el texto 'version=1.0' y 'name=test'. Luego usa edit_file para cambiar 'version=1.0' por 'version=2.0'. Lee el archivo de nuevo para verificar el cambio."

### search_files
19. "Busca en el directorio actual todos los archivos que contengan la palabra 'function'. Usa search_files con el patrón 'function'. Muestra los resultados con el archivo y la línea donde aparece."

### glob_files
20. "Encuentra todos los archivos .ps1 en el directorio actual usando glob_files con el patrón *.ps1. Lista cuántos archivos encontró."

### list_directory
21. "Lista el contenido del directorio actual usando list_directory. Muestra archivos y carpetas con sus tamaños y fechas de modificación."

### get_current_dir
22. "Muestra el directorio de trabajo actual usando get_current_dir."

### web_search
23. "Busca en internet 'PowerShell 7.5 release date' usando web_search. Devuelve los títulos y URLs de los resultados."

### web_fetch
24. "Obtiene el contenido de la URL https://httpbin.org/json usando web_fetch. Devuelve el JSON parseado."

### auto_heal
25. "Simula un error: ejecuta 'Get-Content /ruta/inexistente.txt' que dará error. Luego usa auto_heal para analizar el error y sugerir una solución. Verifica que la sugerencia es útil."

### learn_from_error + find_solution
26. "Usa learn_from_error para registrar: categoría='file_access', problema='Archivo no encontrado al usar Get-Content', solución='Verificar que la ruta existe con Test-Path antes de leer'. Luego usa find_solution buscando 'archivo no encontrado' y verifica que encuentra la solución registrada."

### ocr_image
27. "Si tienes una imagen con texto en el directorio actual (screenshot, foto), usa ocr_image para extraer el texto. Si no hay imagen, describe cómo usarías esta herramienta y qué formatos soporta."

### create_plan + add_plan_step + verify_step + verify_task
28. "Crea un plan para esta tarea: 'Crear un script que haga backup de una carpeta'. Usa create_plan, luego add_plan_step para añadir 3 pasos: 1) identificar la carpeta, 2) crear el script de backup, 3) ejecutar y verificar. Usa verify_step después de cada paso y verify_task al final."

### save_learning
29. "Usa save_learning para guardar un aprendizaje: categoría='command_workflow', información='Para comprimir archivos en PowerShell usar Compress-Archive -Path origen -DestinationPath destino.zip'. Verifica que se guardó."

### list_skills + read_skill
30. "Ejecuta list_skills para mostrar todas las skills disponibles (8 skills). Luego usa read_skill para cargar el skill 'powershell-admin' y describe qué contiene: description, tools to use, workflow."

## ============================================================
## SECCIÓN D: SISTEMAS CORE (31-35)
## ============================================================

### AutoHealing
31. "Provoca un error intencional: ejecuta 'Get-Service ServicioInexistente'. Cuando falle, el sistema AutoHealing debería analizar el error automáticamente. Describe qué sugiere AutoHealing y si la sugerencia es útil."

### AutoImprove + Learning
32. "Registra 3 errores diferentes con learn_from_error (file_access, command_not_found, permission_denied). Luego usa find_solution para buscar cada uno. Verifica que el sistema recuerda todas las soluciones. ¿Cuántas soluciones tiene almacenadas?"

### MemoryDecision
33. "Durante una conversación sobre configuración de red, menciona: 'Siempre prefiero usar Cloudflare DNS 1.1.1.1'. El sistema MemoryDecision debería detectar esto como una preferencia de usuario y guardarla en memoria automáticamente. Verifica ejecutando /memory después."

### Hooks (PreToolUse, PostToolUse, Stop)
34. "Verifica que los hooks están configurados: 1) PreToolUse debe ejecutarse antes de cada tool (verificar en logs), 2) PostToolUse después (verificar en logs), 3) Stop al final de cada turno. Describe cómo crearías un hook que bloquee comandos con 'Remove-Item -Recurse'."

### ReasoningEngine (create_plan, verify_step, verify_task)
35. "Crea un plan complejo de 5 pasos para: 'Auditar la seguridad de un servidor Windows'. Usa create_plan, añade 5 pasos con add_plan_step (cada uno con tool y successCriteria), ejecuta cada paso con verify_step (simulando éxito o fallo), y al final usa verify_task para generar el reporte completo. Verifica que el reporte incluye estado de cada paso, herramientas usadas y archivos creados."

## ============================================================
## SECCIÓN E: AGENT NARRATION + SPEECH (36-37)
## ============================================================

### Narración visual + voz
36. "Ejecuta /narrate on para activar la narración del agente. Luego haz una pregunta compleja como 'explica cómo funciona el DNS' y verifica que: 1) se muestra 'Pensando...' mientras procesa, 2) se narran las acciones de tools, 3) se muestra el resultado. Luego ejecuta /narrate off."

### Text-to-Speech
37. "Ejecuta /speak 'Hola, soy PSCoder y estoy funcionando correctamente'. Verifica que se reproduce audio. Si no hay audio, ejecuta /narrate voice para activar voz y prueba de nuevo con /narrate test."

## ============================================================
## SECCIÓN F: CONTEXTO + MEMORIA PERSISTENTE (38-40)
## ============================================================

### Context Builder (Git + PSCODER.md)
38. "Si estás en un directorio con un repositorio git, ejecuta un comando y verifica que el ContextBuilder detecta: 1) el estado de git (branch, cambios sin commit), 2) si existe un archivo PSCODER.md o README.md, 3) que esta información se incluye en el system prompt."

### Memoria persistente entre sesiones
39. "Guarda en memoria: /memory add 'Mi servidor principal es SRV-PROD-01 con IP 10.0.0.5'. Luego ejecuta /exit para salir. Vuelve a iniciar PSCoder y haz una pregunta relacionada con tu servidor. Verifica que el sistema recuerda la información guardada."

### Historial de sesiones
40. "Después de tener una conversación de varios turnos, ejecuta /exit. Luego inicia PSCoder de nuevo y ejecuta /history para listar las sesiones guardadas. Usa /load <id> para cargar una sesión anterior y verifica que se restaura el contexto completo."

## ============================================================
## SECCIÓN G: INTEGRACIÓN MULTI-TOOL (41-45)
## ============================================================

### Tarea multi-step completa
41. "Tarea completa: 1) Crea una carpeta 'test-pscoder', 2) dentro crea un script 'monitor.ps1' que haga ping a 8.8.8.8, 3) ejecútalo, 4) lee el resultado, 5) si hay errores usa auto_heal, 6) borra la carpeta de prueba. Usa create_plan para planificar, verifica cada paso."

### Análisis de código real
42. "Lee el archivo PSCoder.psm1 completo. Luego: 1) identifica cuántos módulos carga, 2) busca si hay imports duplicados, 3) sugiere 2 mejoras al código, 4) genera un reporte. Usa read_file, search_files, y el skill de refactor."

### Debugging asistido
43. "Crea un script con un bug intencional: '$items = @(1,2,3); foreach ($i in $items) { Write-Host $items[$i] }'. Ejecútalo y cuando veas el resultado incorrecto (muestra 2,3 y un vacío), usa auto_heal para diagnosticar. Luego arregla el código con edit_file y vuelve a ejecutar para verificar."

### Workflow de investigación
44. "Investiga qué es 'Windows Terminal' y cuáles son sus ventajas: 1) usa web_search para buscar información, 2) usa web_fetch para leer la documentación oficial, 3) crea un archivo resumen con los puntos clave, 4) guarda lo aprendido con save_learning."

### Auditoría completa del sistema
45. "Realiza una auditoría completa: 1) lista el directorio actual, 2) lee los 3 archivos más importantes, 3) busca credenciales hardcodeadas (patrón: password=, apiKey=, token=), 4) verifica si hay comandos peligrosos (Invoke-Expression, iex), 5) genera un reporte de seguridad con las conclusiones. Usa create_plan para planificar, ejecuta cada paso, y verify_task al final."

## ============================================================
## SECCIÓN H: PRUEBAS DE RESISTENCIA Y LÍMITES (46-50)
## ============================================================

### Contexto largo
46. "Genera una lista de 50 servidores ficticios (nombre, IP, estado). Luego pide al modelo que analice cuáles están caídos y sugiera acciones. Verifica que el modelo puede manejar un contexto largo sin perder información."

### Múltiples tools en un turno
47. "En una sola petición, pide: 1) listar el directorio, 2) leer un archivo, 3) buscar un patrón, 4) ejecutar un comando. Verifica que el modelo encadena 4 tools en un solo turno sin perder el hilo."

### Auto-compactación
48. "Mantén una conversación larga (más de 20 turnos) con preguntas variadas. Cuando el contexto se acerque al límite, el sistema debería auto-compactar automáticamente. Verifica que después de compactar, el modelo aún recuerda los puntos clave de la conversación."

### Manejo de errores recuperable
49. "Ejecuta un comando que fallará (ej: acceder a un archivo protegido del sistema). Verifica que: 1) el sistema captura el error, 2) AutoHealing sugiere una solución, 3) el modelo puede reintentar con un enfoque diferente, 4) learn_from_error registra el aprendizaje."

### Respuesta multi-formato
50. "Pide al modelo que responda en 3 formatos diferentes: 1) una explicación en texto plano, 2) una tabla en Markdown, 3) un script de PowerShell ejecutable. Verifica que los 3 formatos son correctos y el script funciona al ejecutarlo."

## ============================================================
## CRITERIOS DE EVALUACIÓN POR COMPONENTE (1-10)
## ============================================================

| Componente | Qué evaluar | Score 1-3 | Score 4-6 | Score 7-8 | Score 9-10 |
|-----------|-------------|-----------|-----------|-----------|------------|
| **Skills** | ¿Carga el skill correcto? | No carga skill | Carga pero no sigue workflow | Carga y sigue workflow parcial | Carga, sigue workflow y ejecuta correctamente |
| **Tools** | ¿Ejecuta la tool correcta? | No ejecuta tool | Ejecuta tool pero con errores | Ejecuta correctamente | Ejecuta + verifica resultado |
| **AutoHealing** | ¿Analiza y sugiere? | No analiza | Sugiere genérico | Sugiere específico | Sugiere + aplica fix automático |
| **AutoImprove** | ¿Aprende de errores? | No aprende | Registra pero no recupera | Registra y recupera | Registra, recupera y aplica proactivamente |
| **MemoryDecision** | ¿Guarda automáticamente? | No guarda | Guarda ruido | Guarda info relevante | Guarda + clasifica + recupera |
| **Hooks** | ¿Se ejecutan? | No se ejecutan | Se ejecutan pero no loguean | Se ejecutan y loguean | Se ejecutan, loguean y bloquean correctamente |
| **ReasoningEngine** | ¿Planifica y verifica? | No planifica | Planifica pero no verifica | Planifica y verifica | Planifica, verifica y auto-corrije |
| **Narration** | ¿Narra acciones? | No narra | Narra pero tarde | Narra en tiempo real | Narra + voz + velocidad óptima |
| **Multi-tool** | ¿Encadena tools? | No encadena | Encadena 2 tools | Encadena 3-4 tools | Encadena 5+ tools con verificación |
| **Context** | ¿Maneja contexto largo? | Pierde contexto <10 turnos | Pierde >15 turnos | Auto-compacta bien | Auto-compacta + resume + recuerda todo |

## ============================================================
## RESUMEN DE COMPONENTES PROBADOS
## ============================================================

### 8 Skills
- [ ] code-generation (Test 7)
- [ ] data-extraction (Test 8)
- [ ] debug-error (Test 9)
- [ ] documentation (Test 10)
- [ ] file-analysis (Test 11)
- [ ] powershell-admin (Test 12)
- [ ] refactor (Test 13)
- [ ] web-research (Test 14)

### 20 Tools
- [ ] execute_powershell (Tests 15-16)
- [ ] read_file (Test 17)
- [ ] write_file (Test 17)
- [ ] edit_file (Test 18)
- [ ] search_files (Test 19)
- [ ] glob_files (Test 20)
- [ ] list_directory (Test 21)
- [ ] get_current_dir (Test 22)
- [ ] web_search (Test 23)
- [ ] web_fetch (Test 24)
- [ ] auto_heal (Test 25)
- [ ] learn_from_error (Test 26)
- [ ] find_solution (Test 26)
- [ ] ocr_image (Test 27)
- [ ] create_plan (Test 28)
- [ ] add_plan_step (Test 28)
- [ ] verify_step (Test 28)
- [ ] verify_task (Test 28)
- [ ] save_learning (Test 29)
- [ ] list_skills (Test 30)
- [ ] read_skill (Test 30)

### 5 Sistemas Core
- [ ] AutoHealing (Test 31)
- [ ] AutoImprove (Tests 32, 49)
- [ ] MemoryDecision (Test 33)
- [ ] Hooks (Test 34)
- [ ] ReasoningEngine (Tests 28, 35)

### 3 Providers
- [ ] OpenRouter (Test 3)
- [ ] Groq (Test 3)
- [ ] OrcaRouter (Test 4)

### Slash Commands
- [ ] /help (Test 1)
- [ ] /tools (Test 2)
- [ ] /model (Test 3)
- [ ] /provider (Test 4)
- [ ] /config (Test 5)
- [ ] /memory (Test 6, 39)
- [ ] /narrate (Test 36)
- [ ] /speak (Test 37)
- [ ] /history (Test 40)
- [ ] /load (Test 40)

### Capacidades Avanzadas
- [ ] Narración visual + voz (Test 36-37)
- [ ] Context Builder con Git (Test 38)
- [ ] Memoria persistente (Test 39)
- [ ] Historial de sesiones (Test 40)
- [ ] Multi-tool chaining (Tests 41-45)
- [ ] Contexto largo + auto-compact (Test 48)
- [ ] Manejo de errores recuperable (Test 49)
- [ ] Respuesta multi-formato (Test 50)

### Total: 50 tests cubriendo TODA la funcionalidad de PSCoder
