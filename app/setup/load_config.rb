require "yaml"

config = YAML::load(File.open(File.dirname(__FILE__)+"/../../config/config.yaml"))
env_choice = config["choice"]

settings = config["settings"]
resources = config["resource"]


# perhaps implement way to override temporarily

##### Environment Settings #####
$ENV_FRAMERATE = settings["environment"]["framerate"]
$FRAMERATE_LIMIT = settings["environment"]["framerate_limit"]

env_settings = settings["environment"][env_choice]
$ENV_WIDTH = env_settings["w"]
$ENV_HEIGHT = env_settings["h"]


##### Pond Settings #####
$POND_FOOD_MASS = settings["pond"]["food_mass"]
$POND_POP_LOG_FREQ = settings["pond"]["pop_log_freq"]
$POND_DRAG = settings["pond"]["drag"]

pond_settings = settings["pond"][env_choice]

$POND_INIT_FOOD = pond_settings["food_start"]
$POND_FOOD_RATE = pond_settings["food_rate"]
$POND_INIT_EO = pond_settings["eo_start"]
$POND_REPOP_COUNT = pond_settings["repop"]

##### Eo Constants #####
eo_consts = settings["eo_constants"]

# Main #
$REP_THRESHOLD = eo_consts["main"]["rep_threshold"]
$REP_RATE = eo_consts["main"]["rep_rate"]
$HEAL_DRAIN = eo_consts["main"]["healing_drain"]

# Body #
$B_MASS = eo_consts["body"]["mass"]
$B_RECOVERY = eo_consts["body"]["recovery"]
$B_DAMAGE = eo_consts["body"]["damage"]

# Feeler #
$F_POKE = eo_consts["feeler"]["poke_force_factor"]
$F_MASS = eo_consts["feeler"]["mass_factor"]

# DNA #
$MUTATION_FACTOR = eo_consts["dna"]["mutation_factor"]
$MUTATION_VARIANCE = eo_consts["dna"]["mutation_variance"]
$BRAIN_MUTATE_FACTOR = eo_consts["dna"]["brain_mutate_factor"]
$FORGET_FACTOR = eo_consts["dna"]["forget_factor"]
$DNA_INITIAL_VARIANCE = eo_consts["dna"]["initial_variance"]
$DNA_MUTATION_CURVE = eo_consts["dna"]["mutation_curve"]
$DNA_COLOR_VAR = eo_consts["dna"]["color_var_factor"]

##### Log settings #####
$LOG_POP = settings["log"]["types"]["population"]
$LOG_ACT = settings["log"]["types"]["activity"]

$LOG_POP_FREQ = settings["log"]["pop_freq"]
$LOG_CONSOLE_LEVEL = settings["log"]["console_level"].to_i
$LOG_FILE_LEVEL = settings["log"]["file_level"].to_i

##### Resource settings #####
$FONT_FILE = resources["font_file"]