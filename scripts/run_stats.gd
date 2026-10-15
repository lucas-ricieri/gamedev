extends RefCounted

const WEAPONS = ["sword", "bow", "dagger"]
const NAMES = {"sword":"Espada", "bow":"Arco", "dagger":"Adaga", "grenade":"Granada", "trap":"Armadilha", "potion":"Poção"}
const BASE = {"strength":20.0, "vitality":140.0, "dexterity":1.0, "agility":210.0, "vigor":100.0}
const ATTRIBUTES = ["strength", "vitality", "dexterity", "agility", "vigor"]
const LABELS = {"strength":"FORÇA", "vitality":"VITALIDADE", "dexterity":"DESTREZA", "agility":"AGILIDADE", "vigor":"VIGOR"}
const GAINS = {"strength":4.0, "vitality":25.0, "dexterity":0.10, "agility":14.0, "vigor":20.0}
const DESCRIPTIONS = {"strength":"+4 dano base", "vitality":"+25 vida máxima e cura 25", "dexterity":"+10% velocidade de ataque", "agility":"+14 velocidade de movimento", "vigor":"+20 vigor máximo\n+2 vigor/s"}
var base = BASE.duplicate()
var weapons = {
 "sword":{"damage":1.3, "interval":0.52, "range":76.0, "sweep":140.0, "crit":0.05, "crit_mult":1.7},
 "bow":{"damage":1.0, "interval":0.62, "range":740.0, "speed":620.0, "arrows":1, "crit":0.08, "crit_mult":1.7},
 "dagger":{"damage":0.7, "interval":0.25, "range":48.0, "sweep":80.0, "crit":0.25, "crit_mult":2.0}
}
var specials = {"grenade":{"damage":4.0,"radius":105.0}, "trap":{"damage":2.4,"duration":4.0,"radius":65.0}, "potion":{"heal":0.40}}
var regen = 26.0

func attack_interval(id: String) -> float:
 return maxf(0.08, float(weapons[id].interval) / float(base.dexterity))

func damage(id: String) -> float:
 return float(base.strength) * float(weapons[id].damage)

func roll_damage(id: String) -> Dictionary:
 var critical = randf() < float(weapons[id].crit)
 return {"amount":damage(id) * (float(weapons[id].crit_mult) if critical else 1.0), "critical":critical}

func offers(seed_value: int, wave: int) -> Array:
 var rng = RandomNumberGenerator.new()
 rng.seed = seed_value + wave * 937
 var bonuses = [
 {"target":"sword","key":"damage","amount":0.15,"text":"Espada: +15% do dano base"},
 {"target":"sword","key":"range","amount":6.0,"text":"Espada: +6 alcance"},
 {"target":"bow","key":"speed","amount":70.0,"text":"Arco: +70 velocidade da flecha"},
 {"target":"bow","key":"damage","amount":0.15,"text":"Arco: +15% do dano base"},
 {"target":"bow","key":"arrows","amount":1,"text":"Arco: +1 flecha por disparo (máx. 5)"},
 {"target":"dagger","key":"crit","amount":0.04,"text":"Adaga: +4% chance crítica (máx. 75%)"},
 {"target":"dagger","key":"damage","amount":0.15,"text":"Adaga: +15% do dano base"},
 {"target":"grenade","key":"radius","amount":12.0,"text":"Granada: +12 raio da explosão"},
 {"target":"grenade","key":"damage","amount":0.4,"text":"Granada: +40% do dano base"},
 {"target":"trap","key":"duration","amount":0.6,"text":"Armadilha: +0,6 s de imobilização"},
 {"target":"trap","key":"damage","amount":0.3,"text":"Armadilha: +30% do dano base"},
 {"target":"potion","key":"heal","amount":0.05,"text":"Poção: +5% de cura (máx. 80%)"}
 ]
 var result = []
 for id in ATTRIBUTES:
  var index = rng.randi_range(0, bonuses.size()-1)
  var extra = bonuses.pop_at(index)
  result.append({"attribute":id,"extra":extra})
 return result

func apply_offer(offer: Dictionary):
 var id = offer.attribute
 base[id] += GAINS[id]
 if id == "vigor": regen += 2.0
 var extra = offer.extra
 var target = weapons[extra.target] if weapons.has(extra.target) else specials[extra.target]
 target[extra.key] += extra.amount
 if extra.key == "crit": target[extra.key] = minf(0.75, target[extra.key])
 if extra.key == "arrows": target[extra.key] = mini(5, int(target[extra.key]))
 if extra.key == "heal": target[extra.key] = minf(0.8, target[extra.key])

func serialize() -> Dictionary:
 return {"base":base.duplicate(true),"weapons":weapons.duplicate(true),"specials":specials.duplicate(true),"regen":regen}

func restore(value: Dictionary):
 for id in BASE:
  base[id] = maxf(BASE[id], float(value.get("base",{}).get(id,BASE[id])))
 for id in weapons:
  for key in weapons[id]:
   weapons[id][key] = value.get("weapons",{}).get(id,{}).get(key,weapons[id][key])
 for id in specials:
  for key in specials[id]:
   specials[id][key] = value.get("specials",{}).get(id,{}).get(key,specials[id][key])
 regen = maxf(26.0, float(value.get("regen",26.0)))
