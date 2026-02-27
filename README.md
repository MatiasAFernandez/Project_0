**Project-0**
El siguiente proyecto consiste en un videojuego en 2D desarrollado en el motor Godot v4.5.1.

**Desarrollo**
Se busca desarrollar el juego de manera ordenada y estructurada aplicando de manera adecuada técnicas profesionales de desarrollo de videojuegos como patrones de diseño con el objetivo de obtener un producto estable, óptimo, escalable y funcional. 
Actualmente el juego ya se encuentra en desarrollo y a continuación se describe el estado actual del mismo.

**Estructura de Carpetas** 
res://
├── _core/ # Lógica Global y Singletons (Autoloads)
│   ├── autoloads/
│   │   ├── AudioManager.gd # Gestiona buses, fade-ins/outs de   música y SFX
│   │   ├── NavigationManager.gd # Controla la transición entre escenas (Zonas)
│   │   ├── SettingsManager.gd # Abstrae elementos generales de la configuración
│   │   ├── TimeManager.gd # Ciclo Día/Noche (Mañana, Tarde, Noche, Medianoche)
│   │   ├── EventBus.gd # Señales globales (Observer Pattern)
│   │   ├── AudioSettings.gd # Maneja la configuración del audio en el menú
│   │   ├── VideoSettings.gd # Maneja la configuración de video en el menú
│   │   ├── CursorManager.gd # Permite modificar el sprite del cursor
│   │   ├── UIManager.gd # Gestiona los diferentes elementos de la UI 
│   │   └── PlayerSession.gd # Persistencia: Stats, Inventario, QuestLog actuales
│   ├── constants/ # Enums (Tipos de daño, Fases del día, IDs de Zonas)
│   └── utils/ 
├── assets/ # Archivos "crudos" (Importados)
│   ├── audio/
│   │   ├── music/
│   │   │   ├── exploration/ # Música tranquila por zonas (Market_Theme.ogg)
│   │   │   ├── combat/ # Música intensa (Boss_Battle.ogg, Normal_Fight.ogg)
│   │   │   └── events/ # Momentos emotivos/narrativos
│   │   └── sfx/
│   │       ├── ui/ # Clicks, hovers, abrir inventario, pasar página
│   │       ├── combat/ # Espadazos, bloqueos (parry), golpes, gritos
│   │       └── ambience/ # Viento, lluvia, gente en el mercado
│   ├── art/
│   │   ├── backgrounds/ # Imágenes de fondo para las Zonas (Alta resolución)
│   │   │   ├── parallax_layers/ # Capas separadas para efecto profundidad
│   │   │   └── static/ # Fondos completos planos
│   │   ├── characters/
│   │   │   ├── portraits/ # Expresiones para diálogos (Normal, Enojado, Feliz)
│   │   │   └── sprites/ # Spritesheets para COMBATE (Animaciones Idle, Attack, etc)
│   │   ├── items/ # Iconos para el Inventario (Espadas, Pociones, Cartas)
│   │   ├── ui/ # Skins de ventanas, botones, barras de vida, cursor custom
│   │   └── vfx/ # Texturas para partículas (chispas, brillo mágico)
│   └── fonts/ # Tipografías (Título, Texto legible, Números)
├── data/ # Definiciones de Datos (Resources .tres)
│   ├── enemies/ # Stats de enemigos (Slime.tres, Bandit.tres)
│   ├── events/ # Datos de eventos basados en días
│   ├── locations/ # Datos de zonas (conexiones entre zonas, eventos por tiempo)
│   ├── npcs/ # Para recursos de NPCs (diálogos, stats, rutas)
│   ├── recipes/ # Datos para crafteos
│   ├── items/ # Definición de ítems (Nombre, Descripción, Textura, Precio)
│   │   ├── consumables/
│   │   ├── equipment/
│   │   └── quest_items/
│   ├── quests/ # Misiones (Objetivos, Recompensas)
│   └── skills/ # Habilidades de combate
├── game/ # Escenas y Lógica del Juego
│   ├── exploration/ # MODO POINT-AND-CLICK
│   │   ├── locations/ # Escenas (.tscn) de cada lugar (Plaza, Taberna)
│   │   │   └── BaseLocation.gd # Plantilla de locación
│   │   ├── interactables/ # Prefabs: Puertas, NPCs estáticos, Objetos
│   │   │   └── ClickableArea.gd # Plantilla de elemento interactuable
│   │   └── visual_effects/ # Iluminación 2D, Lluvia, Niebla (Nodos de ambiente)
│   ├── combat/ # MODO BATALLA
│   │   ├── arenas/ # Fondos de batalla (bosque_battle_bg.tscn)
│   │   ├── battlers/ # Escenas de pjs en batalla (PlayerBattler, EnemyBattler)
│   │   ├── mechanics/ # Lógica de hitbox, hurtbox, parry system
│   │   └── ui/ # HUD de combate (QTEs, Barras de vida flotantes)
│   ├── narrative/ # MODO NOVELA VISUAL
│   │   ├── dialogues/ # Archivos de diálogo (Json o Resource)
│   │   └── cutscenes/ # Escenas scripteadas especiales
│   ├── inventory/
│   │   └── resources/ # Elementos que almacenará el inventario
│   │       ├── ItemData.gd # Lógica de los ítems
│   │       └── SlotData.gd # Lógica para equipar los items
│   ├── ui/ # Interfaz de Usuario (CanvasLayer)
│   │   ├── common/ # Componentes reusables (Botones animados, Sliders)
│   │   ├── hud/ # La interfaz principal (Reloj, Botón Inventario, Mini-mapa)
│   │   ├── inventory/ # Ventana de inventario, GridContainer, Slots
│   │   │   ├── ContextMenu.gd # Menú contextual para investigar items
│   │   │   ├── EquipmentSlotUI.gd # Maneja los slots de equipamiento
│   │   │   ├── InventoryDropZone.gd # Arrastrar y soltar items
│   │   │   ├── InventoryListDropZone.gd # Soltar ítems en la lista
│   │   │   ├── InventorySlotUI.gd # UI del ítem en el inventario
│   │   │   ├── InventoryUI.gd # Maneja la lógica general del inventario
│   │   │   └── ItemTooltip.gd # proporciona info extra sobre los ítems
│   │   ├── journal/ # Diario de misiones y Bestiario
│   │   ├── dialogue_box/ # La caja de texto visual novel
│   │   ├── shops/ # Interfaz de compra/venta
│   │   └── menus/ # Main Menu, Pause Menu, Game Over
│   │   │   ├── tabs/ # pestañas del menú de pausa
│   │   │   │   ├── AudioTab.gd # pestaña de Audio del menú de pausa
│   │   │   │   ├── GeneralTab.gd # pestaña General del menú de pausa
│   │   │   │   ├── VideoTab.gd # pestaña Video del menú de pausa
│   │   │   │   └── ControlsTab.gd # pestaña de Controles del menú de pausa
│   │   │   ├── OptionsMenu.gd # Maneja las distintas pestañas (tabs)
│   │   │   ├── PauseMenu.gd # Maneja el menú de pausa
├── addons/ # Almacena plugins de terceros o personalizados
└── tests/ # Sandbox para probar mecánicas aisladas sin romper el juego

**Características Principales del Juego**
La jugabilidad se basa en tres pilares fundamentales:
**Exploración:** Durante la exploración el juego adopta la perspectiva de una novela visual en donde el jugador recorre varios escenarios o zonas (imágenes estáticas con efecto de parallax) en los cuales podrá interactuar con diferentes elementos que existan en el escenario mediante el manejo del cursor, como pueden ser: objetos recogibles (son agregados al inventario al interactuar con ellos), objetos interactuables (como palancas o botones que activan ciertos eventos como cambios en el escenario o permiten progresar en alguna misión), entradas, puertas o caminos (permiten al jugador desplazarse de un escenario a otro) y personajes o npc (al interactuar con estos el juego cambia a un modo de diálogo con el npc, en donde se presentarán diferentes opciones de texto para el jugador, lo cual le permitirá realizar diferentes acciones con el npc, cómo obtener información sobre algún determinado lugar, evento o personaje, aceptar misiones, recibir recompensas por misiones ya completadas, entrar en combate con el npc o comerciar con ellos).
El mundo explorable del juego se divide en grandes distritos a los cuales se accede mediante un mapa. Cada distrito está compuesto por diferentes escenarios conectados entre sí por entradas, puertas o caminos. El jugador puede viajar directamente entre diferentes escenarios si estos están conectados mediante alguna entrada, puerta o camino pero para viajar a otros distritos debe hacerlo necesariamente a través del mapa.

**Narrativa:** La historia principal es el núcleo del juego que determina el progreso del jugador. Esta historia se irá desarrollando a medida que el jugador realice ciertas misiones, hable con ciertos personajes o interactúe con ciertos objetos o lugares. Las decisiones que el jugador tome determinarán como la historia se desenvuelve impactando en las recompensas que el jugador obtendrá así como los enemigos con los cual tendrá que enfrentarse y los eventos que experimentará. Para que la historia tenga un peso importante dentro del juego, es necesario que los personajes que participan en ella se desarrollen de igual manera, por eso, además de la campaña principal, ciertos npc tendrán sus propias rutas, que existirán en paralelo a la historia principal y contarán con desenlaces que varían dependiendo de las decisiones del jugador.  

**Combate:** El último pilar fundamental del juego es el sistema de combate, el cual consiste en batallas pve en tiempo real en donde el jugador deberá realizar sus acciones en el momento correcto (timing) para causar el mayor daño al adversario o para reducir o evitar el daño recibido.
Cuando el jugador se encuentre con algún enemigo hostil, al interactuar con él, el juego entrará en el modo de combate en donde se visualiza al jugador del lado izquierdo de la pantalla y al enemigo del lado derecho de la misma. Por debajo se encontrará el menú de accesos rápidos y de habilidades del jugador así como su estado de salud y efectos aplicados (positivos y negativos) también en el menú pero debajo del enemigo se encontrarán datos relevantes al mismo como su salud, efectos aplicados y otras cuestiones como su armadura peor ejemplo.
El equipo que el jugador utilice es importante ya que determinará las habilidades que pueda utilizar en combate:
>> Si utiliza escudos tiene la capacidad de realizar parry, al presionar una tecla en un momento justo del ataque del enemigo desviando el ataque y dejándolo expuesto a un golpe crítico.
>> Los escudos se pueden utilizar para proteger al jugador y el sistema de protección funciona de la siguiente manera: al presionar y mantener presionado la tecla de defensa el jugador levanta el escudo y se protege con él, esto hace que el jugador se vaya fatigando cuanto más tiempo mantenga el escudo levantado y la fatiga del escudo es también su protección, es decir, que el escudo solo absorberá el daño equivalente a la protección que posea en el instante de tiempo t al recibir el ataque del enemigo. Ejemplo: el jugador posee un escudo con protección p y levanta el escudo manteniendo la defensa por un instante de tiempo t, en t el enemigo ataca con un daño d, como el tiempo pasó p actual = p - fatiga(t) siendo fatiga() la función que disminuye la protección a medida que el escudo permanece levantado. Entonces el daño recibido por el jugador será igual a: daño recibido = d - p actual, si el daño recibido es menor a cero entonces simplemente se igual a cero y si el daño del enemigo es mayor a la protección actual entonces romperá la defensa del jugador y lo dejará vulnerable a ataques, el jugador tendrá que esperar un tiempo de cooldown para poder levantar el escudo. (estas fórmulas no son definitivas y pueden sufrir cambios en su implementación, solo sirven de manera descriptiva para entender el sistema)
>> En el caso de que el jugador no tenga ningún escudo equipado, puede seguir defendiéndose y el sistema de protección se aplica de igual manera pero al no tener escudo su protección es menor y siempre recibirá algo de daño al ser atacado con la defensa alta pero en este caso la protección no disminuye con el tiempo, solo con los ataques enemigos.
>> Otra mecánica con la cual el jugador cuenta es el esquive, el cual permite anular el daño recibido si se presiona la tecla de esquive en el momento justo antes de que el ataque del enemigo impacte. Una vez activado el esquive este tendrá un tiempo de cooldown antes de poder volver a usarse. Este tiempo de espera varía dependiendo del peso del personaje y de su resistencia. Cada elemento equipado aporta peso al personaje y lo hace más lento, este efecto puede disminuir aumentando atributos como fuerza y resistencia.
>> Posteriormente existirán los tipos de ataques, siendo estos dos (ataque ligero y ataque pesado). La diferencia entre ambos es el tiempo de espera al usarlos, siendo los ataques pesados más lentos en recargarse y poder volver a usarlos y también en el daño que causan.
>> El jugador también podrá ejecutar habilidades especiales que irá aprendiendo a lo largo del juego obtenidas de otros personajes o compradas en tiendas. Estas habilidades pueden ser ataques con efectos elementales como fuego, pasivas que puedan apilarse proporcionando ventajas o debuff que puedan aplicarse al enemigo. 

Ninguno de estos elementos fundamentales del juego están definidos completamente todavía (especialmente el sistema de combate). Se irán actualizando y agregando elementos de calidad de vida de ser necesarios.

Otros sistemas importantes
**Sistema de Tiempo:** El juego plantea un sistema que permita que el tiempo pase así como los días. Cada día se dividirá en cuatro secciones (Mañana, Tarde, Noche y Medianoche), el tiempo solo avanzará dentro del juego cuando el jugador complete alguna misión o realice alguna actividad (la cantidad de secciones de tiempo que se avanzara dependerá de la misión o actividad, algunas solo harán pasar a la siguiente sección de tiempo mientras que otras consumiran todo el dia). Dependiendo del tiempo del día los escenarios cambiarán haciendo que ciertos objetos, personajes o actividades solo sean interactuables o estén disponibles en ciertos momentos del día de manera que el jugador tenga que administrar su tiempo y decidir en qué gastarlo. Este sistema también permite que puedan suceder eventos llegados a cierta cantidad de días dentro del juego jugados.
**Sistema de Inventario:** El jugador a lo largo de su aventura recogerá varios ítems de diferentes tipos (armaduras, armas, objetos de misión, etc.), es importante que pueda acceder a un menú en donde pueda visualizar cada ítem que posee, saber para qué sirve y poder equiparlo o consumirlo de ser posible. El inventario consiste en dos partes, por un lado (mitad izquierda del inventario) se encuentra la sección de equipamiento en donde están los diferentes slots para que el jugador pueda equipar tanto armas como armaduras que le servirán en combate, por otro lado (mitad derecha del inventario) existirá una lista de los ítems que el jugador posee los cuales podrá inspeccionar, filtrar, ordenar, destruir, equipar, consumir y vender dependiendo del tipo de ítem en cuestión. Algunos ítems pueden apilarse y el inventario posee una capacidad máxima que puede expandirse con items especiales.  
**Sistema RPG:** Especialmente para el modo de combate pero también para ciertos diálogos el jugador contará con atributos que podrá mejorar realizando ciertas actividades. A lo largo del mundo existirán varias actividades en distintos tiempos del día que el jugador deberá descubrir explorando, estas actividades consistirán en minijuegos que el jugador deberá completar para poder aumentar alguno de sus atributos. Cada atributo se divide en diez niveles los cuales piden cierta cantidad de puntos de experiencia para pasar al siguiente nivel de dicho atributo, la cantidad de experiencia que da una actividad depende del desempeño del jugador en el minijuego. Los atributos que el jugador posee son:
Fuerza: Aumenta el daño de los ataques, permite equipar armaduras y equipos más pesados y puede ser usado en ciertos check de diálogos.
Agilidad: Aumenta la tasa de críticos, mejora el tiempo de espera del esquive y de los ataques y puede ser usado en ciertos check de diálogos.
Resistencia: Aumenta la vida máxima, reduce la fatiga al usar la defensa del escudo, aumenta la resistencia a debuff elementales y puede ser utilizado en ciertos check de diálogos.
Inteligencia: Permite aprender recetas más elaboradas, mejora la recolección de recursos y puede ser utilizado en ciertos check de diálogos.
Carisma: Permite obtener mejores descuentos en las tiendas  y puede ser utilizado en ciertos check de diálogos.
**Sistema de Relaciones:** Como la narrativa es parte esencial del juego, aquellos personajes que tengan sus propias rutas o historias secundarias deben tener un indicador que marque el tipo de relación que el jugador tiene con el personaje (enemigos, amigos, conocidos, etc.) Este indicador irá cambiando dependiendo de las decisiones que el jugador tome dentro de la ruta del personaje.
**Sistema de Mapa:** Es necesario un mapa que permita al jugador viajar a los distintos distritos dentro del juego. Al comienzo algunos distritos estarán bloqueados y el jugador deberá avanzar en la historia (principal o secundarias) para poder desbloquearlos.
**Sistema de Diario:** Es necesario un diario que le permita al jugador rastrear el progreso de las misiones que tiene activas, las misiones que ya completo así como el estado de las relaciones con los personajes importantes que conoció. También debe tener un bestiario que le permita ver todas las criaturas o enemigos con las que se enfrentó así como un codex que revele cierta información sobre el mundo.
**Sistema de Crafteo:** Como resultado de los combates así como de las diferentes tiendas dentro del juego, el jugador obtendrá recursos que podrá utilizar para crear diferentes ítems que podrá usar tanto en batalla como en eventos o actividades especiales. Estos ítems crafteables requieren de recetas que se pueden conseguir en distintas partes del juego. 
        
   
