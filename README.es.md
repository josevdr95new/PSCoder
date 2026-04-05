# PSCoder

[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue)](https://github.com/PowerShell/PowerShell)
[![GitHub repo](https://img.shields.io/badge/GitHub-PSCoder-blue?logo=github)](https://github.com/josevdr95new/PSCoder)

Asistente de programacion con IA que se ejecuta en tu terminal de PowerShell. Usa las APIs de OpenRouter o Groq para entender tu codigo, editar archivos, buscar en la web y resolver problemas de forma autonoma.

**Repositorio:** https://github.com/josevdr95new/PSCoder

## Caracteristicas

### Capacidades Principales
- **19 Herramientas Integradas** - Operaciones de archivos, ejecucion de shell, busqueda web, OCR y mas
- **8 Skills Especializados** - Flujos de trabajo predefinidos para debugging, generacion de codigo, investigacion web y mas
- **Memoria Persistente** - Memoria a largo plazo que persiste entre sesiones
- **Auto-Aprendizaje** - Guarda automaticamente errores, soluciones y patrones para referencia futura
- **Auto-Recuperacion** - Diagnostica errores y sugiere soluciones con enfoques alternativos
- **Historial de Sesiones** - Guarda, lista y carga conversaciones anteriores

### Herramientas
| Herramienta | Descripcion |
|-------------|-------------|
| `execute_powershell` | Ejecutar comandos PowerShell (ventana oculta, no interrumpe el chat) |
| `read_file` | Leer contenido de archivos |
| `write_file` | Crear o sobrescribir archivos |
| `edit_file` | Reemplazar texto en archivos existentes |
| `search_files` | Buscar patrones en archivos (grep) |
| `glob_files` | Encontrar archivos por patron (soporta `**`) |
| `list_directory` | Listar archivos y directorios |
| `web_search` | Buscar en la web (Brave API + DuckDuckGo como respaldo) |
| `web_fetch` | Obtener contenido de URLs (soporta Markdown para Agentes) |
| `ocr_image` | Extraer texto de imagenes (OCR de Windows) |
| `auto_heal` | Analizar errores y obtener sugerencias de solucion |
| `learn_from_error` | Registrar soluciones para referencia futura |
| `find_solution` | Buscar problemas resueltos anteriormente |
| `create_plan` | Crear planes estructurados paso a paso |
| `verify_step` | Verificar ejecucion de pasos individuales |
| `verify_task` | Verificar resultado completo de una tarea |
| `save_learning` | Guardar aprendizajes automaticamente |
| `list_skills` | Listar flujos de trabajo especializados disponibles |
| `read_skill` | Cargar instrucciones de un skill |

### Skills (Habilidades)
| Skill | Proposito |
|-------|-----------|
| **Web Research** | Buscar, obtener y sintetizar informacion actualizada de la web |
| **File Analysis** | Analizar estructura de proyectos, codebases y configuraciones |
| **Debug Error** | Diagnosticar y resolver errores con solucion sistematica |
| **Code Generation** | Crear scripts, funciones y modulos nuevos desde cero |
| **Refactor** | Mejorar calidad, legibilidad y rendimiento del codigo |
| **PowerShell Admin** | Tareas de administracion de sistemas Windows |
| **Data Extraction** | Parsear y transformar datos de archivos, APIs y paginas web |
| **Documentation** | Crear y mejorar documentacion de proyectos |

### Sistemas Inteligentes
- **Memory Decision** - Analiza conversaciones automaticamente y guarda informacion valiosa
- **Reasoning Engine** - Planifica, ejecuta y verifica tareas de multiples pasos
- **Sistema de Permisos** - Herramientas seguras auto-aprobadas, herramientas peligrosas requieren confirmacion
- **Hooks** - Hooks de ejecucion pre/post herramienta para comportamiento personalizado
- **Context Builder** - Incluye automaticamente estado de Git y contexto del proyecto
- **Agent Narration** - Retroalimentacion visual y por voz para acciones del agente

## Instalacion

### Requisitos
- PowerShell 5.1 o posterior (Windows 10/11)
- Una clave API de [OpenRouter](https://openrouter.ai) o [Groq](https://groq.com)

### Configuracion
```powershell
# Clonar el repositorio
git clone https://github.com/josevdr95new/PSCoder.git
cd PSCoder

# Importar el modulo
Import-Module .\PSCoder.psd1

# Configurar tu clave API (elige una)
# Opcion 1: Variable de entorno
$env:OPENROUTER_API_KEY = "tu-clave-aqui"

# Opcion 2: Configuracion interactiva
Start-PSCoder
# Luego usa: /config apiKey tu-clave-aqui
```

## Configuracion

### Claves API
```powershell
# OpenRouter (recomendado - acceso a muchos modelos)
$env:OPENROUTER_API_KEY = "tu-clave"

# Groq (inferencia rapida)
$env:GROQ_API_KEY = "tu-clave"

# Brave Search (opcional, para mejor busqueda web)
$env:BRAVE_SEARCH_API_KEY = "tu-clave"
```

### Modelos
```powershell
# Dentro de PSCoder, cambiar modelo
/model openai/gpt-4o
/model google/gemini-2.5-flash
/model qwen/qwen3.6-plus:free

# Cambiar proveedor
/provider openrouter
/provider groq
```

## Uso

### Iniciar PSCoder
```powershell
Start-PSCoder
```

### Comandos
| Comando | Descripcion |
|---------|-------------|
| `/help` | Mostrar todos los comandos |
| `/clear` | Limpiar conversacion |
| `/new` | Nueva conversacion (recargar memoria) |
| `/model` | Cambiar modelo de IA |
| `/provider` | Cambiar proveedor |
| `/history` | Listar sesiones guardadas |
| `/load <id>` | Cargar una sesion anterior |
| `/memory` | Mostrar memoria a largo plazo |
| `/memory add X` | Agregar informacion a la memoria |
| `/memory edit` | Abrir archivo de memoria |
| `/memory clear` | Limpiar memoria |
| `/tools` | Listar herramientas disponibles |
| `/config` | Mostrar/cambiar configuracion |
| `/narrate on` | Activar narracion del agente |
| `/narrate off` | Desactivar narracion |
| `/speak <texto>` | Hablar texto personalizado |
| `/exit` | Guardar y salir |

### Ejemplo de Flujo de Trabajo
```
> Como arreglo este error de PowerShell: "El termino 'Get-Foo' no se reconoce"?

[La IA carga el skill: debug-error]
[La IA busca soluciones previas]
[La IA sugiere la solucion y explica]

> Crea un script que monitoree el espacio en disco y alerte cuando baje del 10%

[La IA carga el skill: code-generation]
[La IA crea un plan con pasos]
[La IA escribe el script usando write_file]
[La IA prueba el script usando execute_powershell]
[La IA verifica el resultado]
```

## Arquitectura

```
PSCoder/
├── API/                    # Clientes de API (OpenRouter, Groq)
│   ├── BaseClient.ps1      # Cliente HTTP compartido con reintentos
│   ├── OpenRouter.ps1      # Integracion con OpenRouter
│   └── Groq.ps1            # Integracion con Groq
├── Commands/
│   └── SlashCommands.ps1   # Manejador de comandos slash
├── Config/
│   └── Config.ps1          # Gestion de configuracion
├── Core/                   # Nucleo del sistema
│   ├── AgentNarration.ps1  # Retroalimentacion visual y por voz
│   ├── AutoHealing.ps1     # Diagnostico y recuperacion de errores
│   ├── AutoImprove.ps1     # Sistema de aprendizaje
│   ├── ContextBuilder.ps1  # Contexto de Git y proyecto
│   ├── Hooks.ps1           # Hooks pre/post ejecucion
│   ├── Init.ps1            # Inicializacion de subsistemas
│   ├── Logger.ps1          # Sistema de logging
│   ├── Main-Loop.ps1       # Bucle principal REPL
│   ├── MemoryDecision.ps1  # Decisiones automaticas de memoria
│   ├── Permissions.ps1     # Sistema de permisos
│   ├── ReasoningEngine.ps1 # Planificacion y verificacion
│   └── SystemPrompt.ps1    # Constructor de prompt del sistema
├── History/
│   └── History.ps1         # Guardar/cargar sesiones
├── Memory/
│   └── Memory.ps1          # Memoria persistente (MEMORY.md)
├── Skills/                 # Definiciones de flujos especializados
│   ├── code-generation.md
│   ├── data-extraction.md
│   ├── debug-error.md
│   ├── documentation.md
│   ├── file-analysis.md
│   ├── powershell-admin.md
│   ├── refactor.md
│   └── web-research.md
├── Tools/                  # Implementaciones individuales de herramientas
│   ├── Cache.ps1           # Sistema de cache
│   ├── EditFile.ps1
│   ├── ExecutePowerShell.ps1
│   ├── GlobFiles.ps1
│   ├── Invoke-Tool.ps1     # Despachador de herramientas
│   ├── ListDirectory.ps1
│   ├── OcrImage.ps1
│   ├── ReadFile.ps1
│   ├── SearchFiles.ps1
│   ├── SkillManager.ps1    # Descubrimiento/carga de skills
│   ├── ToolRegistry.ps1    # Esquemas de herramientas para LLM
│   ├── WebFetch.ps1
│   ├── WebSearch.ps1
│   └── WriteFile.ps1
├── UI/
│   └── Formatter.ps1       # Formato de salida CLI
├── PSCoder.psd1            # Manifiesto del modulo
├── PSCoder.psm1            # Cargador del modulo
├── Start-PSCoder.ps1       # Script de inicio rapido
├── Iniciar-PSCoder.bat     # Lanzador de Windows
├── Test-Human.ps1          # Pruebas completas
├── Test-PSCoder.ps1        # Pruebas del modulo
└── Verify-Fixes.ps1        # Verificacion de correcciones
```

## Almacenamiento de Datos

Todos los datos del usuario se guardan en `~/.pscoder/`:
```
~/.pscoder/
├── config.json             # Configuracion (claves API, modelo, etc.)
├── MEMORY.md               # Memoria a largo plazo
├── Sessions/               # Sesiones de conversacion guardadas
├── improve/
│   ├── learnings.json      # Aprendizajes registrados
│   └── patterns.json       # Patrones aprendidos
├── cache/                  # Cache de busqueda/obtencion web
├── reasoning/              # Historial de planes
├── memory_decisions/       # Registro de decisiones automaticas
└── hooks/                  # Scripts de hooks personalizados
```

**No se almacenan claves API ni datos sensibles en el repositorio.**

## Licencia

MIT
