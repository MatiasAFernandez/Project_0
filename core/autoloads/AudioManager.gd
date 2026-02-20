extends Node

# ==============================================================================
# CONSTANTES Y CONFIGURACIÓN
# ==============================================================================
const MIN_VOLUME_DB: float = -80.0
const MAX_VOLUME_DB: float = 0.0
const SFX_POOL_SIZE: int = 12

@export var default_fade_duration: float = 2.0

## Nombre del Bus de Audio para la música (debe existir en la pestaña Audio)
@export var music_bus: String = "Music"
## Nombre del Bus de Audio para los efectos (debe existir en la pestaña Audio)
@export var sfx_bus: String = "SFX"

# ==============================================================================
# VARIABLES INTERNAS
# ==============================================================================
# Sistema de Música
var _current_music_player: AudioStreamPlayer
var _next_music_player: AudioStreamPlayer
var _music_tween: Tween

# Sistema de SFX
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_sfx_index: int = 0

# ==============================================================================
# MÉTODOS DEL CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Inicializamos todo por código para que sea "Plug & Play"
	_initialize_music_system()
	_initialize_sfx_pool()

# ==============================================================================
# SISTEMA DE MÚSICA
# ==============================================================================
func play_music(new_stream: AudioStream, fade_duration: float = -1.0) -> void:
	if fade_duration < 0:
		fade_duration = default_fade_duration
	
	# 1. Si ya suena lo mismo, no hacer nada
	if _current_music_player.stream == new_stream and _current_music_player.playing:
		return
	
	# 2. Si es null, detener música actual con fade out
	if new_stream == null:
		_fade_out_current(fade_duration)
		return
	
	# 3. Intercambio de reproductores (Ping-Pong)
	var temp = _current_music_player
	_current_music_player = _next_music_player
	_next_music_player = temp
	
	# 4. Configurar el nuevo track
	_current_music_player.stream = new_stream
	_current_music_player.volume_db = MIN_VOLUME_DB
	_current_music_player.play()
	
	# 5. Transición Crossfade
	_kill_music_tween()
	_music_tween = create_tween()
	
	# Usamos 'parallel' para que ambos cambios de volumen ocurran a la vez
	_music_tween.parallel().tween_property(_next_music_player, "volume_db", MIN_VOLUME_DB, fade_duration)
	_music_tween.parallel().tween_property(_current_music_player, "volume_db", MAX_VOLUME_DB, fade_duration)
	
	# Usamos 'chain' para esperar a que termine el fade antes de detener el antiguo
	_music_tween.chain().tween_callback(_next_music_player.stop)

func _fade_out_current(duration: float) -> void:
	if not _current_music_player.playing:
		return
	
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_current_music_player, "volume_db", MIN_VOLUME_DB, duration)
	_music_tween.tween_callback(_current_music_player.stop)

func _kill_music_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()

# ==============================================================================
# SISTEMA DE SFX
# ==============================================================================
func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if stream == null:
		return
	
	# Obtenemos el siguiente reproductor disponible (Round Robin)
	var player = _get_next_sfx_player()
	
	player.stream = stream
	
	# Variación de tono
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()

func play_ui_click() -> void:
	# play_sfx(preload("res://assets/audio/ui/click.wav"), 0.1)
	pass

# ==============================================================================
# INICIALIZACIÓN (PRIVADO)
# ==============================================================================
func _initialize_music_system() -> void:
	# Creamos dos reproductores idénticos para alternar entre ellos
	_current_music_player = _create_player("MusicTrack_1", music_bus)
	_next_music_player = _create_player("MusicTrack_2", music_bus)

func _initialize_sfx_pool() -> void:
	var sfx_container = Node.new()
	sfx_container.name = "SFXPool"
	add_child(sfx_container)
	
	# Verificamos si el bus existe para evitar errores
	var target_bus = sfx_bus
	if AudioServer.get_bus_index(sfx_bus) == -1:
		push_warning("AudioManager: El bus '%s' no existe. Usando 'Master'." % sfx_bus)
		target_bus = "Master"
	
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFX_%02d" % i # Formato SFX_00, SFX_01...
		player.bus = target_bus
		sfx_container.add_child(player)
		_sfx_players.append(player)

# Helper para crear reproductores de música
func _create_player(name_str: String, bus_str: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = name_str
	
	if AudioServer.get_bus_index(bus_str) != -1:
		player.bus = bus_str
	
	player.volume_db = MIN_VOLUME_DB
	add_child(player)
	return player

func _get_next_sfx_player() -> AudioStreamPlayer:
	var player = _sfx_players[_current_sfx_index]
	
	# Si justo este reproductor estaba sonando (raro con un pool de 12), lo cortamos
	if player.playing:
		player.stop()
		
	# Avanzamos el índice circularmente
	_current_sfx_index = (_current_sfx_index + 1) % SFX_POOL_SIZE
	
	return player
