== Clase 4 

== Arquitectura de Firmware

Al desarrollar sistemas embebidos complejos, se manejan múltiples periféricos y tareas concurrentes. Para evitar que el firmware se vuelva inmanejable y difícil de depurar, se emplea un diseño modular estructurado en capas de abstracción bien definidas.

=== Capas e Interfaces
La arquitectura organiza los distintos módulos en una jerarquía clara:
- *Capa de Aplicación (APP)*: Es la capa de mayor jerarquía. Contiene la lógica del negocio o del funcionamiento del equipo. Sigue las reglas de la programación tradicional y es independiente del tiempo real. Nunca debe interactuar con los periféricos ni leer o escribir sus registros de forma directa; se comunica únicamente a través de los servicios de los drivers.
- *Capa de Drivers (DRV)*: Son las librerías de hardware encargadas de configurar y controlar los periféricos físicos. Resuelven las restricciones temporales del sistema y agregan versatilidad. Se subdividen en:
  - *Peripheral Drivers (MCAL)*: Capa de Abstracción del Microcontrolador. Configura directamente los registros de los periféricos internos del chip (como PORT, ADC, PIT o FTM). Al migrar de microcontrolador, solo esta capa debe modificarse.
  - *Hardware Drivers (HAL)*: Capa de Abstracción de Hardware. Se encarga de controlar los elementos externos que están conectados al microcontrolador (como un sensor de temperatura externo, displays o un driver de motor). Al cambiar un componente externo, solo se altera esta capa.
  - *Complex Drivers*: Módulos integrados que unifican el control de registros y hardware externo debido a limitaciones de tiempo extremadamente críticas o simplicidad del sistema.

=== Reglas de Diseño y Buenas Prácticas (Tips)
El diseño del firmware es deficiente si se detectan estas prácticas:
- Leer o escribir registros de periféricos directamente desde la aplicación.
- Escribir todo el código del proyecto en un único archivo.
- Diseñar un driver acoplado a un solo proyecto sin posibilidad de reutilización.
- Incluir la definición de registros del microcontrolador (como el archivo cabecera principal) en el header público de un driver.
- Permitir que un módulo incluya la cabecera de un módulo de jerarquía superior.

== Diseño de Drivers

El driver es el canal de comunicación entre la aplicación y el hardware. Dependiendo de los requerimientos de tiempo real y de la velocidad de los eventos, se eligen distintos esquemas de sincronización.

=== Patrones de Interacción Temporal

+ *Código Bloqueante (Busy Wait)*:
  - El driver inicia una acción de hardware y detiene por completo la ejecución de la CPU en un bucle cerrado hasta que el evento finaliza.
  - Genera una gran subutilización del procesador, impidiendo realizar otras tareas concurrentes.

+ *Polling No Bloqueante (Esquema de tres servicios)*:
  - El driver no bloquea la CPU; actúa como un intermediario que enmascara los registros del hardware.
  - Expone tres servicios básicos: comenzar la tarea, consultar el estado actual (listo o no listo) y leer el resultado.
  - Permite al programa principal intercalar otras funciones mientras el hardware trabaja.

+ *Polling Periódico (Periodic Interrupt o Hardware Polling)*:
  - Es el método preferido para procesar eventos lentos (como un pulsador mecánico).
  - Un temporizador genera una interrupción periódica fija (PISR) para realizar el muestreo del periférico a intervalos regulares (ej. cada 10 milisegundos).
  - El driver captura el evento, filtra rebotes por software y almacena el estado para que la aplicación lo consuma cuando lo requiera, evitando la pérdida de información si ocurre un único evento por intervalo.

+ *Controlado por Interrupciones (Interrupt Driven)*:
  - El periférico activa una señal de interrupción al finalizar una tarea o detectar un cambio físico.
  - La CPU suspende la aplicación solo para atender la rutina de interrupción rápida del driver (ISR), eliminando la subutilización por consultas constantes.

+ *Interrupción con Callback*:
  - El hardware genera una interrupción, el driver la procesa y ejecuta inmediatamente una función proporcionada por la aplicación (el callback) dentro de la misma ISR.
  - *Advertencia de diseño*: El callback se ejecuta dentro del contexto crítico de la interrupción. Por lo tanto, nunca debe realizar tareas lentas, retardos activos o llamadas bloqueantes.


== Temporizadores Periódicos y Sincronización

La sincronización periódica asegura que las consultas y temporizaciones del sistema se realicen de forma regular y precisa.

==== Inicialización de Base de Tiempo Periódica (Systick)
El temporizador SysTick es un contador descendente de 24 bits integrado en el núcleo Cortex-M4. Su secuencia correcta de configuración por hardware requiere:
+ Programar el valor de recarga deseado en el registro *RVR*. Para lograr un período de N ciclos de reloj, el valor cargado debe ser exactamente N - 1.
+ Borrar el valor actual escribiendo cualquier valor en el registro *CVR*, lo cual limpia el contador y la bandera de desbordamiento.
+ Habilitar el contador, su interrupción de excepción y el origen de reloj en el registro de control *CSR*.

==== Atomicidad en Variables Compartidas
Al transferir datos entre las rutinas de interrupción (ISR / PISR) y el lazo principal de la aplicación, es fundamental evitar la corrupción de datos:
- Las variables modificadas por hardware o dentro de una interrupción deben declararse con el calificador *volatile* para que el compilador no optimice las lecturas almacenando valores en los registros internos de la CPU.
- Toda variable compartida cuyo tamaño sea mayor al bus de datos del procesador (32 bits) debe leerse y escribirse como una operación atómica. Esto se logra deshabilitando temporalmente las interrupciones globales antes del acceso en el lazo principal y reactivándolas inmediatamente después para evitar condiciones de carrera.
