extends OmniLight3D
## Poste elétrico da cidade: luz fixa (sem a chama tremulando do
## lantern_pulse.gd, que é das lanternas a fogo do calm_place). Só acende e
## apaga pelo ciclo de dia e noite (grupo "street_lamps", `intensity` 0..1).

@export var base_energy: float = 2.2
@export var lamp_color: Color = Color(1.0, 0.82, 0.55)  ## branco-quente de lâmpada
@export_range(0.0, 1.0) var intensity: float = 1.0      ## controlado pelo day_night_cycle.gd

func _ready() -> void:
	add_to_group("street_lamps")
	light_color = lamp_color
	_apply()

func _process(_delta: float) -> void:
	_apply()

func _apply() -> void:
	light_energy = base_energy * intensity
	visible = intensity > 0.01
