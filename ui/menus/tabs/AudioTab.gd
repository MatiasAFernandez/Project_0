extends Control
class_name AudioTab

# ==============================================================================
# REFERENCIAS UI
# ==============================================================================
# Ajusta las rutas según tu escena real
@onready var _slider_master: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MasterRow/MasterSlider
@onready var _slider_music: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicRow2/MusicSlider
@onready var _slider_sfx: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXRow/SFXSlider

# Nodo de audio para feedback al mover sliders (opcional pero recomendado)
@onready var _test_sfx: AudioStreamPlayer = $TestAudioStreamPlayer

# Timer para evitar que el sonido de prueba suene 60 veces por segundo al arrastrar
var _test_sound_cooldown: float = 0.0

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	_setup_sliders()
	_connect_signals()
	_sync_ui_from_backend()

func _process(delta: float) -> void:
	if _test_sound_cooldown > 0:
		_test_sound_cooldown -= delta

# ==============================================================================
# CONFIGURACIÓN INICIAL
# ==============================================================================
func _setup_sliders() -> void:
	# Configuramos rangos (0 a 1)
	for s in [_slider_master, _slider_music, _slider_sfx]:
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05 # Pasos de 5%

func _connect_signals() -> void:
	# UI -> Backend
	_slider_master.value_changed.connect(_on_master_changed)
	_slider_music.value_changed.connect(_on_music_changed)
	_slider_sfx.value_changed.connect(_on_sfx_changed)
	
	# Backend -> UI (Para sincronizar si se resetean opciones)
	# Asumimos que AudioSettings emite 'volume_changed'
	AudioSettings.volume_changed.connect(_on_backend_update)

# ==============================================================================
# EVENTOS DE UI
# ==============================================================================

func _on_master_changed(value: float) -> void:
	AudioSettings.set_master_volume(value)

func _on_music_changed(value: float) -> void:
	AudioSettings.set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	AudioSettings.set_sfx_volume(value)
	_try_play_test_sound()

# ==============================================================================
# SINCRONIZACIÓN
# ==============================================================================

func _sync_ui_from_backend() -> void:
	# Usamos set_value_no_signal para evitar loops o sonidos de prueba al abrir el menú
	_slider_master.set_value_no_signal(AudioSettings.get_volume(AudioSettings.BUS_MASTER))
	_slider_music.set_value_no_signal(AudioSettings.get_volume(AudioSettings.BUS_MUSIC))
	_slider_sfx.set_value_no_signal(AudioSettings.get_volume(AudioSettings.BUS_SFX))

func _on_backend_update(bus_name: String, value: float) -> void:
	match bus_name:
		AudioSettings.BUS_MASTER: _slider_master.set_value_no_signal(value)
		AudioSettings.BUS_MUSIC: _slider_music.set_value_no_signal(value)
		AudioSettings.BUS_SFX: _slider_sfx.set_value_no_signal(value)

# ==============================================================================
# EXTRA: FEEDBACK AUDITIVO
# ==============================================================================
func _try_play_test_sound() -> void:
	# Solo reproducimos si pasó el tiempo de enfriamiento (ej. 0.1s)
	# y si tenemos un nodo asignado
	if _test_sfx and _test_sound_cooldown <= 0:
		# Nos aseguramos que salga por el bus de SFX
		if _test_sfx.bus != AudioSettings.BUS_SFX:
			_test_sfx.bus = AudioSettings.BUS_SFX
			
		_test_sfx.play()
		_test_sound_cooldown = 0.15 # Esperar 150ms antes del próximo sonido
