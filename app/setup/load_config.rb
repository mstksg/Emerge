require "yaml"

yaml_config = YAML::load(File.open($LOADING_PATH+"/config/config.yaml"))
$env_choice = yaml_config["default_choice"] if $env_choice == nil

def process_config yaml_hash
  total_override = yaml_hash["override"]
  
  $env_choice = yaml_hash["default_choice"] if $env_choice == nil
  
  default_override = total_override["default_overrides"]
  profile_override = total_override["setting_overrides"][$env_choice]
  
  overrode_config = yaml_hash["settings"].clone
  overrode_config = fill_tree overrode_config,default_override if default_override
  overrode_config = fill_tree overrode_config,profile_override if profile_override
  
  yaml_hash["settings"] = overrode_config
  
  return yaml_hash
end

def fill_tree filler,override_bank
  
  override_bank = {} unless override_bank
  
  filled = {}
  for i in filler.keys
    if filler[i].class == Hash
      filled[i] = fill_tree filler[i],override_bank
    else
      if override_bank[i]
        filled[i] = override_bank[i]
      else
        filled[i] = filler[i]
      end
    end
  end
  
  return filled
end

def setup_constants config_hash
  
  settings = config_hash["settings"]
  resources = config_hash["resource"]

  ##### Environment Settings #####
  $ENV_FRAMERATE = settings["environment"]["framerate"]
  $FRAMERATE_LIMIT = settings["environment"]["framerate_limit"]
  $ARCHIVE_LIMIT = settings["environment"]["eo_archive_limit"]
  $ARCHIVE_CLEANUP = settings["environment"]["eo_archive_cleanup"]
  
  env_settings = settings["environment"][$env_choice]
  $ENV_WIDTH = env_settings["w"]
  $ENV_HEIGHT = env_settings["h"]
  
  ##### Pond Settings #####
  $POND_FOOD_MASS = settings["pond"]["food_mass"]
  $POND_DRAG = settings["pond"]["drag"]
  $POND_SPIKE_DECAY = settings["pond"]["spike_decay"]
  $POND_DISASTER = settings["pond"]["pond_disaster"]
  $POND_ENERGY_INFUSION = settings["pond"]["energy_infusion"]
  $AUTO_TRACKING = settings["pond"]["auto_track"] if $AUTO_TRACKING == nil
  
  pond_settings = settings["pond"][$env_choice]
  
  $POND_INIT_FOOD = pond_settings["food_start"]
  $POND_FOOD_RATE = pond_settings["food_rate"]
  $POND_INIT_EO = pond_settings["eo_start"]
  $POND_REPOP_COUNT = pond_settings["repop"]
  
  ##### Eo Constants #####
  eo_consts = settings["eo_constants"]

  # Main #
  $EO_STARTING_ENERGY = eo_consts["main"]["eo_starting_energy"]
  $REP_VARIANCE = eo_consts["main"]["rep_variance"]
  $REP_RATE = eo_consts["main"]["rep_rate"]
  $REP_RATE_DEGREE = eo_consts["main"]["rep_rate_degree"]
  $REP_MINIMUM = eo_consts["main"]["rep_t_minimum"]
  $REP_MAXIMUM = eo_consts["main"]["rep_t_maximum"]
  $ENERGY_CAP = eo_consts["main"]["energy_cap"]
  $HEAL_DRAIN_MIN = eo_consts["main"]["healing_drain_min"]
  $HEAL_DRAIN_MAX = eo_consts["main"]["healing_drain_max"]
  $SPIKE_DAMAGE = eo_consts["main"]["spike_damage"]
  $MASS_DRAG = eo_consts["main"]["mass_drag"]
  $REST_ENERGY_DECAY = eo_consts["main"]["rest_energy_decay"]
  $BASE_DRAG_REDUCTOR = eo_consts["main"]["base_drag_reductor"]
  
  # Body #
  $B_MASS_FACTOR = eo_consts["body"]["body_mass_factor"]
  $B_RECOVERY = eo_consts["body"]["recovery"]
  $B_DAMAGE = eo_consts["body"]["body_damage"]
  $B_DECAY = eo_consts["body"]["body_decay"]
  $B_MAX_SPEED = eo_consts["body"]["max_speed"]
  
  # Feeler #
  $F_POKE = eo_consts["feeler"]["poke_force_factor"]
  $F_MASS = eo_consts["feeler"]["feeler_mass_factor"]
  $F_L_S_RATIO = eo_consts["feeler"]["length_strength_mass_ratio"]
  
  # DNA #
  $MUTATE_TIME_SCALE = eo_consts["dna"]["mutate_time_scale"]
  $MUTATION_FACTOR = eo_consts["dna"]["mutation_factor"] / $MUTATE_TIME_SCALE
  $MUTATION_VARIANCE = eo_consts["dna"]["mutation_variance"] / $MUTATE_TIME_SCALE
  $BRAIN_MUTATE_FACTOR = eo_consts["dna"]["brain_mutate_factor"] / $MUTATE_TIME_SCALE
  $FORGET_FACTOR = eo_consts["dna"]["forget_factor"] / $MUTATE_TIME_SCALE
  $DNA_INITIAL_VARIANCE = eo_consts["dna"]["initial_variance"]
  $DNA_MUTATION_CURVE = eo_consts["dna"]["mutation_curve"]
  $DNA_COLOR_VAR = eo_consts["dna"]["color_var_factor"] / $MUTATE_TIME_SCALE
  $PROGRAM_SIZE_LIMIT = eo_consts["dna"]["program_size_limit"]
  $CONTAINER_SIZE_LIMIT = eo_consts["dna"]["container_size_limit"]
  
  ##### Log settings #####
  $LOG_POP = settings["log"]["types"]["population"] if $LOG_POP == nil
  $LOG_ACT = settings["log"]["types"]["activity"] if $LOG_ACT == nil
  $LOG_FR = settings["log"]["types"]["framerate"] if $LOG_FR == nil
  
  $LOG_POP_FREQ = settings["log"]["pop_freq"]
  $LOG_FR_FREQ = settings["log"]["fr_freq"]
  $LOG_CONSOLE_LEVEL = settings["log"]["console_level"].to_i if $LOG_CONSOLE_LEVEL == nil
  $LOG_FILE_LEVEL = settings["log"]["file_level"].to_i
  
  ##### Resource settings #####
  $FONT_FILE = resources["font_file"]
  
end

yaml_config = YAML::load(File.open($LOADING_PATH+"/config/config.yaml"))
config = process_config yaml_config
setup_constants config