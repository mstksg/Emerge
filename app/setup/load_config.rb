require "yaml"

config = YAML::load(File.open(File.dirname(__FILE__)+"/../../config/config.yaml"))
settings = config["settings"]

## Log settings
$LOG_POP = settings["log"]["types"]["population"]
$LOG_ACT = settings["log"]["types"]["activity"]

$LOG_POP_FREQ = settings["log"]["pop_freq"]
$LOG_CONSOLE_LEVEL = settings["log"]["console_level"].to_i
$LOG_FILE_LEVEL = settings["log"]["file_level"].to_i


## Pond Settings
$POND_FOOD_MASS = settings["pond"]["food_mass"]
$POND_LOG_FREQ = settings["pond"]["log_freq"]
$POND_DRAG = settings["pond"]["drag"]
$POND_FRAMERATE = settings["pond"]["framerate"]
$POND_ZONES = settings["pond"]["zones"]

env_choice = settings["pond"]["choice"]
env_settings = settings["pond"][env_choice]

$POND_WIDTH = env_settings["w"]
$POND_HEIGHT = env_settings["h"]
$POND_INIT_FOOD = env_settings["food_start"]
$POND_FOOD_RATE = env_settings["food_rate"]
$POND_INIT_EO = env_settings["eo_start"]
$POND_REPOP_COUNT = env_settings["repop"]

## Eo Constants
eo_consts = settings["eo_constants"]

## Main
$REP_THRESHOLD = eo_consts["main"]["rep_threshold"]
$REP_RATE = eo_consts["main"]["rep_rate"]
$HEAL_DRAIN = eo_consts["main"]["healing_drain"]

## Body
$B_MASS = eo_consts["body"]["mass"]
$B_RECOVERY = eo_consts["body"]["recovery"]
$B_DAMAGE = eo_consts["body"]["damage"]

## Feeler
$F_POKE = eo_consts["feeler"]["poke_force_factor"]
$F_MASS = eo_consts["feeler"]["mass_factor"]

## DNA
$MUTATION_FACTOR = eo_consts["dna"]["mutation_factor"]
$MUTATION_VARIANCE = eo_consts["dna"]["mutation_variance"]
$FORGET_FACTOR = eo_consts["dna"]["forget_factor"]