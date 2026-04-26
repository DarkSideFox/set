extends Control # Root UI node (like a Flutter Scaffold/Column root)

# --- ENUMS ---
# These define all possible values for each card property.
# Internally they are just integers (0, 1, 2...), but we use names for clarity.
enum ShapeType { DIAMOND, CIRCLE, PILL }
enum TextureType { FAN, SQUARE, FLOWER }
enum ColorType { RED, GREEN, BLUE }

# --- DATA CLASS ---
# This is a lightweight object representing a single SET card.
class SetCard:
	var texture   # TextureType enum value
	var shape     # ShapeType enum value
	var color     # ColorType enum value
	var count     # Number of symbols on the card (1–3)
	
	func _init(_texture, _shape, _color, _count):
		# Constructor assigns values when a card is created
		texture = _texture
		shape = _shape
		color = _color
		count = _count

# --- DECK GENERATION ---
# Creates the full SET deck (3×3×3×3 = 81 cards)
func new_deck():
	var cards = []  # Array that will hold all cards
	
	# Iterate through every possible combination of properties
	for shape in ShapeType.values():
		for tex in TextureType.values():
			for clr in ColorType.values():
				for count in range(1, 4):  # 1, 2, 3
					cards.append(SetCard.new(tex, shape, clr, count))
	
	return cards  # Return full deck

# --- SET VALIDATION ---
# Checks if 3 cards form a valid SET
func is_set(cards):
	if cards.size() != 3:
		return false  # A set must contain exactly 3 cards
	
	# Dictionaries used like sets (keys only matter, values are irrelevant)
	var shapes = {}
	var textures = {}
	var colors = {}
	var counts = {}
	
	# Collect unique values for each property
	for c in cards:
		shapes[c.shape] = true
		textures[c.texture] = true
		colors[c.color] = true
		counts[c.count] = true
	
	# SET rule:
	# For each property → either all same (size == 1) OR all different (size == 3)
	return (shapes.size() == 1 or shapes.size() == 3) \
	and (textures.size() == 1 or textures.size() == 3) \
	and (colors.size() == 1 or colors.size() == 3) \
	and (counts.size() == 1 or counts.size() == 3)

# --- FIND ALL POSSIBLE SETS (COMBINATIONS) ---
# Recursively builds combinations of 3 cards and checks each one
func get_all_sets(idx, current_set, cards, all_sets):
	# Loop through remaining cards starting from index
	for i in range(idx, cards.size()):
		
		# Duplicate current selection and add a new card
		var potential = current_set.duplicate()
		potential.append(cards[i])
		
		if potential.size() == 3:
			# If we reached 3 cards, check if it's a valid set
			if is_set(potential):
				all_sets.append(potential)
		else:
			# Otherwise keep building the combination recursively
			get_all_sets(i + 1, potential, cards, all_sets)

# --- CHECK IF A NEW SET OVERLAPS EXISTING ONES ---
# Ensures sets do not share cards
func do_sets_overlap(sets, candidate_set):
	var all_cards = []
	
	# Flatten all existing sets into one list
	for s in sets:
		all_cards += s
	
	# Add the candidate set
	all_cards += candidate_set
	
	var possible_sets = []
	
	# Recompute all sets from combined cards
	get_all_sets(0, [], all_cards, possible_sets)
	
	# If adding this set creates extra unintended sets → overlap exists
	return not (possible_sets.size() == sets.size() + 1)

# --- GENERATE NON-OVERLAPPING SETS ---
# Builds multiple valid sets that don't interfere with each other
func get_non_overlapping_sets(current_set, desired_sets, all_cards, results):
	if results.size() == desired_sets:
		return  # Stop when we have enough sets
	
	for card in all_cards:
		if card not in current_set:  # Avoid reusing same card in one set
			
			var potential = current_set.duplicate()
			potential.append(card)
			
			if potential.size() == 3:
				# Check if it's valid and doesn't overlap with existing sets
				if is_set(potential) and not do_sets_overlap(results, potential):
					results.append(potential)
			else:
				# Continue building the set recursively
				get_non_overlapping_sets(potential, desired_sets, all_cards, results)

# --- IMAGE PATH GENERATION ---
# Converts enum values into a file path string
func get_shape_asset(shape, texture, color):
	return "res://assets/shapes/%s_%s_%s.png" % [
		ShapeType.keys()[shape].to_lower(),     # Convert enum to string
		TextureType.keys()[texture].to_lower(),
		ColorType.keys()[color].to_lower()
	]

# --- CREATE SHAPE VIEW ---
# Builds the visual representation of a card's shapes
func create_shape_view(card):
	var container = VBoxContainer.new()
	container.size_flags_vertical =Control.SIZE_EXPAND_FILL
	
	# Add one image per "count"
	for i in range(card.count):
		var texture_rect = TextureRect.new()
		
		# Prevent resizing distortion
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Load image based on card properties
		var path = get_shape_asset(card.shape, card.texture, card.color)
		texture_rect.texture = load(path)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(100, 60)
		
		container.add_child(texture_rect)
	
	return container

# --- CREATE CARD UI ---
# Wraps shape view inside a styled panel
func create_card_view(card):
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(150, 220)  # Card size
	
	# Margin container adds padding inside card
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 10)
	panel.add_child(margin)
	
	# Add shapes inside padded area
	var content = create_shape_view(card)
	margin.add_child(content)
	
	return panel

# --- MAIN ENTRY POINT ---
# Equivalent to Flutter's initState + build combined
func _ready():
	var deck = new_deck()  # Create full deck
	deck.shuffle()         # Randomize order
	
	var results = []
	
	# Generate 4 valid non-overlapping sets (12 cards total)
	get_non_overlapping_sets([], 4, deck, results)
	
	var cards = []
	
	# Flatten sets into a single list
	for s in results:
		cards += s
	
	cards.shuffle()  # Shuffle again for randomness
	
	# Root vertical layout (rows stacked vertically)
	var grid = VBoxContainer.new()
	add_child(grid)
	
	# Create 4 rows
	for y in range(4):
		var row = HBoxContainer.new()
		grid.add_child(row)
		
		# Each row has 3 cards
		for x in range(3):
			var card = cards.pop_back()  # Take last card
			
			# Create UI for the card
			var view = create_card_view(card)
			
			# Add to row
			row.add_child(view)
