require "yaml"

config = YAML::load(File.open(File.dirname(__FILE__)+"/../../config/config.yaml"))
settings = config["settings"]

## Environment Settings
$ENV_FOOD_MASS = settings["environment"]["food_mass"]
$ENV_LOG_FREQ = settings["environment"]["log_freq"]
$ENV_DRAG = settings["environment"]["drag"]

env_choice = settings["environment"]["choice"]
env_settings = settings["environment"][env_choice]

$ENV_WIDTH = env_settings["w"]
$ENV_HEIGHT = env_settings["h"]
$ENV_INIT_FOOD = env_settings["food_start"]
$ENV_FOOD_RATE = env_settings["food_rate"]

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
$FORGET_FACTOR = eo_consts["dna"]["forget_factor"]