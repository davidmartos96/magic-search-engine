describe "Deck legality" do
  include_context "db"

  def parse_decklist(decklist)
    parser = DeckParser.new(db, decklist)
    Deck.new(parser.main_cards, parser.sideboard_cards)
  end

  def build_deck_of_size(mb, sb)
    parse_decklist <<~EOF
    #{mb}x Forest
    Sideboard
    #{sb}x Mountain
    EOF
  end

  def parse_decklist_for_commander(*cards)
    parse_decklist <<~EOF
    100x Forest
    Sideboard
    #{ cards.join("\n") }
    EOF
  end

  def assert_valid_commander(*cards)
    deck = parse_decklist_for_commander(*cards)
    deck.should be_valid_commander
    deck.should be_valid_brawler
  end

  def assert_valid_brawler_only(*cards)
    deck = parse_decklist_for_commander(*cards)
    deck.should_not be_valid_commander
    deck.should be_valid_brawler
  end

  def assert_invalid_commander(*cards)
    deck = parse_decklist_for_commander(*cards)
    deck.should_not be_valid_commander
    deck.should_not be_valid_brawler
  end

  it "allowed_in_any_number?" do
    db.printings.select(&:allowed_in_any_number?).map(&:name).uniq.should match_array([
      "Forest",
      "Island",
      "Mountain",
      "Persistent Petitioners",
      "Plains",
      "Rat Colony",
      "Relentless Rats",
      "Shadowborn Apostle",
      "Snow-Covered Forest",
      "Snow-Covered Island",
      "Snow-Covered Mountain",
      "Snow-Covered Plains",
      "Snow-Covered Swamp",
      "Swamp",
      "Wastes",
    ])
  end

  describe "valid_commander" do
    it "empty is not valid" do
      assert_invalid_commander
    end

    it "2 of the same are invalid" do
      assert_invalid_commander "2x Urabrask the Hidden"
      assert_invalid_commander "2x Rowan Kenrith"
      assert_invalid_commander "2x Bruse Tarl, Boorish Herder"
    end

    it "3 or more are invalid" do
      assert_invalid_commander "Emrakul, the Aeons Torn", "Urabrask the Hidden", "Isperia, Supreme Judge"
    end

    it "nonlegendary is invalid" do
      assert_invalid_commander "Etched Monstrosity"
      assert_invalid_commander "Goblin Guide"
    end

    it "noncreature is invalid" do
      assert_invalid_commander "Blackblade Reforged"
    end

    it "secondary doesn't count, deck parser will flip to front side if you ask for secondary" do
      assert_invalid_commander "Autumn-Tail, Kitsune Sage"
      assert_invalid_commander "Withengar Unbound"

      assert_valid_commander "Archangel Avacyn"
      # Deck parser changes is to Archangel Avacyn, which is totally fine
      assert_valid_commander "Avacyn, the Purifier"

      assert_valid_commander "Bruna, the Fading Light"
      assert_valid_commander "Gisela, the Broken Blade"
      # Deck parser changes this to Bruna, the Fading Light, which is questionable
      assert_valid_commander "Brisela, Voice of Nightmares"
    end

    it "is valid if primary side is valid" do
      assert_valid_commander "Chandra, Roaring Flame"
    end

    it "legendary creature in any colors is valid" do
      assert_valid_commander "Emrakul, the Aeons Torn"
      assert_valid_commander "Urabrask the Hidden"
      assert_valid_commander "Isperia, Supreme Judge"
      assert_valid_commander "Glissa, the Traitor"
      assert_valid_commander "Breya, Etherium Shaper"
      assert_valid_commander "Niv-Mizzet Reborn"
    end

    it "planeswalkers are only valid if they say so" do
      assert_valid_brawler_only "Tibalt, the Fiend-Blooded"
      assert_valid_brawler_only "Karn Liberated"
      assert_valid_commander "Nahiri, the Lithomancer"
    end

    it "Commander partners are valid alone or with another partner" do
      assert_valid_commander "Bruse Tarl, Boorish Herder"
      assert_valid_commander "Sidar Kondo of Jamuraa"
      assert_valid_commander "Bruse Tarl, Boorish Herder", "Sidar Kondo of Jamuraa"
      assert_invalid_commander "Bruse Tarl, Boorish Herder", "Karn, Silver Golem"
    end

    it "BBD partners are valid alone or with designated partner" do
      assert_valid_commander "Rowan Kenrith"
      assert_valid_commander "Will Kenrith"
      assert_valid_commander "Rowan Kenrith", "Will Kenrith"
      assert_valid_commander "Virtus the Veiled"
      assert_valid_commander "Gorm the Great"
      assert_valid_commander "Gorm the Great", "Virtus the Veiled"
      assert_invalid_commander "Rowan Kenrith", "Gorm the Great"
      assert_invalid_commander "Ravos, Soultender", "Gorm the Great"
      assert_invalid_commander "Glissa, the Traitor", "Gorm the Great"
      assert_invalid_commander "Gorm the Great", "Rowan Kenrith"
      assert_invalid_commander "Gorm the Great", "Ravos, Soultender"
      assert_invalid_commander "Gorm the Great", "Glissa, the Traitor"
    end

    it "non-legendary BBD partners are not valid" do
      assert_invalid_commander "Blaring Captain"
      assert_invalid_commander "Blaring Captain", "Blaring Recruiter"
    end

    it "exact printing doesn't matter" do
      assert_valid_commander "1x [BBD:255] [foil] Rowan Kenrith", "1x [BBD:2] Will Kenrith"
      assert_valid_commander "1x [PBBD:255s] [foil] Rowan Kenrith", "1x [BBD:2] Will Kenrith"
    end

    it "uncards are valid" do
      assert_valid_commander "Richard Garfield, Ph.D."
      assert_valid_brawler_only "Urza, Academy Headmaster"
    end
  end

  describe "deck_size_issues" do
    # Limited
    let(:legality_40_0) { format.deck_size_issues(build_deck_of_size(40, 0)) }
    let(:legality_40_22) { format.deck_size_issues(build_deck_of_size(40, 22)) }

    # Constructed
    let(:legality_60_0) { format.deck_size_issues(build_deck_of_size(60, 0)) }
    let(:legality_60_15) { format.deck_size_issues(build_deck_of_size(60, 15)) }
    let(:legality_61_15) { format.deck_size_issues(build_deck_of_size(61, 15)) }
    let(:legality_240_15) { format.deck_size_issues(build_deck_of_size(240, 15)) }

    # Brawl
    let(:legality_59_1) { format.deck_size_issues(build_deck_of_size(59, 1)) }
    let(:legality_58_2) { format.deck_size_issues(build_deck_of_size(58, 2)) }

    # Commander
    let(:legality_99_1) { format.deck_size_issues(build_deck_of_size(99, 1)) }
    let(:legality_98_2) { format.deck_size_issues(build_deck_of_size(99, 1)) }

    # Random weird sizes
    let(:legality_100_0) { format.deck_size_issues(build_deck_of_size(100, 0)) }
    let(:legality_99_16) { format.deck_size_issues(build_deck_of_size(99, 16)) }

    Format.all_format_classes.each do |format_class|
      describe format_class do
        let(:format) { format_class.new }
        it do
          case format
          when FormatBrawl
            legality_40_0.should match_array([
              "Deck must contain exactly 60 cards, has 40",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 0"])
            legality_40_22.should match_array([
              "Deck must contain exactly 60 cards, has 62",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 22"])
            legality_60_0.should match_array([
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 0"])
            legality_60_15.should match_array([
              "Deck must contain exactly 60 cards, has 75",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 15"])
            legality_61_15.should match_array([
              "Deck must contain exactly 60 cards, has 76",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 15"])
            legality_240_15.should match_array([
              "Deck must contain exactly 60 cards, has 255",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 15"])
            legality_59_1.should be_empty
            legality_58_2.should be_empty
            legality_99_1.should match_array([
              "Deck must contain exactly 60 cards, has 100"])
            legality_98_2.should match_array([
              "Deck must contain exactly 60 cards, has 100"])
            legality_100_0.should match_array([
              "Deck must contain exactly 60 cards, has 100",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 0"])
            legality_99_16.should match_array([
              "Deck must contain exactly 60 cards, has 115",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 16"])

          when FormatCommander, FormatDuelCommander, FormatMTGOCommander
            legality_40_0.should match_array([
              "Deck must contain exactly 100 cards, has 40",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 0"])
            legality_40_22.should match_array([
              "Deck must contain exactly 100 cards, has 62",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 22"])
            legality_60_0.should match_array([
              "Deck must contain exactly 100 cards, has 60",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 0"])
            legality_60_15.should match_array([
              "Deck must contain exactly 100 cards, has 75",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 15"])
            legality_61_15.should match_array([
              "Deck must contain exactly 100 cards, has 76",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 15"])
            legality_240_15.should match_array([
              "Deck must contain exactly 100 cards, has 255",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 15"])

            legality_59_1.should match_array([
              "Deck must contain exactly 100 cards, has 60"])
            legality_58_2.should match_array([
              "Deck must contain exactly 100 cards, has 60"])
            legality_99_1.should be_empty
            legality_98_2.should be_empty
            legality_100_0.should match_array([
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 0"])
            legality_99_16.should match_array([
              "Deck must contain exactly 100 cards, has 115",
              "Deck's sideboard must be exactly 1 card or 2 partner cards designated as commander, has 16"])

          else
            legality_40_0.should match_array([
              "Deck must contain at least 60 mainboard cards, has only 40"])
            legality_40_22.should match_array([
              "Deck must contain at least 60 mainboard cards, has only 40",
              "Deck must contain at most 15 sideboard cards, has 22"])
            legality_60_0.should be_empty
            legality_60_15.should be_empty
            legality_61_15.should be_empty
            legality_240_15.should be_empty

            legality_59_1.should match_array([
              "Deck must contain at least 60 mainboard cards, has only 59"])
            legality_58_2.should match_array([
              "Deck must contain at least 60 mainboard cards, has only 58"])
            # Commander decks just so happen to be legal Constructed decks
            legality_99_1.should be_empty
            legality_98_2.should be_empty
            legality_100_0.should be_empty
            legality_99_16.should match_array([
              "Deck must contain at most 15 sideboard cards, has 16"])
          end
        end
      end
    end
  end

  describe "deck_card_issues" do
    let(:vintage) { FormatVintage.new }
    let(:deck) {
      parse_decklist <<~EOF
      1x Lightning Bolt
      3x [M10] Birds of Paradise
      2x Forest
      7x Mountain
      2x Black Lotus
      1x Mox Pearl
      15x Shadowborn Apostle
      4x Relentless Rats
      7x Amulet of Quoz
      1x Bronze Tablet
      3x Aerial Toastmaster
      1x Ancestral Recall

      Sideboard
      2x [M11] Birds of Paradise
      1x Mox Pearl
      1x Mox Diamond
      4x Relentless Rats
      12x Rat Colony
      19x Snow-Covered Island
      1x Eager Beaver
      12x Embrace My Diabolical Vision
      EOF
    }

    it do
      vintage.deck_card_issues(deck).should match_array([
        "Deck contains 5 copies of Birds of Paradise, only up to 4 allowed",
        "Deck contains 2 copies of Black Lotus, which is restricted to only up to 1 allowed",
        "Deck contains 2 copies of Mox Pearl, which is restricted to only up to 1 allowed",
        "Deck contains Amulet of Quoz which is banned",
        "Deck contains Bronze Tablet which is banned",
        "Deck contains Aerial Toastmaster which is not in the format",
        "Deck contains Eager Beaver which is not in the format",
        "Deck contains Embrace My Diabolical Vision which is not in the format",
      ])
    end
  end

  describe "deck_card_issues for singleton formats" do
    let(:duel) { FormatDuelCommander.new }
    let(:deck) {
      parse_decklist <<~EOF
      1x Lightning Bolt
      1x [M10] Birds of Paradise
      1x [M11] Birds of Paradise
      2x Forest
      7x Mountain
      1x Eager Beaver
      2x Embrace My Diabolical Vision
      1x Black Lotus
      15x Shadowborn Apostle
      4x Relentless Rats
      7x Amulet of Quoz
      1x Bronze Tablet
      1x Aerial Toastmaster
      1x Ancestral Recall
      1x Prime Speaker Vannifar
      2x Edric, Spymaster of Trest

      Sideboard
      1x Mox Pearl
      1x Mox Diamond
      1x Giant Growth
      12x Rat Colony
      19x Snow-Covered Island
      1x Baral, Chief of Compliance
      EOF
    }
    it do
      duel.deck_card_issues(deck).should match_array([
        "Deck contains 2 copies of Birds of Paradise, only up to 1 allowed",
        "Deck contains Eager Beaver which is not in the format",
        "Deck contains Embrace My Diabolical Vision which is not in the format",
        "Deck contains Black Lotus which is banned",
        "Deck contains Amulet of Quoz which is banned",
        "Deck contains Bronze Tablet which is banned",
        "Deck contains Aerial Toastmaster which is not in the format",
        "Deck contains Ancestral Recall which is banned",
        "Deck contains Mox Pearl which is banned",
        "Deck contains Mox Diamond which is banned",
        "Deck contains 2 copies of Edric, Spymaster of Trest, only up to 1 allowed",
      ])
    end
  end

  describe "deck_card_issues for brawl" do
    # Lock time as it's a rotating format
    let(:brawl) { FormatBrawl.new(Date.parse("2019-07-01")) }
    let(:deck) {
      parse_decklist <<~EOF
      1x Lightning Bolt
      1x Sorcerous Spyglass
      2x Black Lotus
      3x Karn, the Great Creator
      1x Bulwark Giant

      Sideboard
      2x Ajani's Pridemate
      1x Bond of Discipline
      1x Bulwark Giant
      EOF
    }

    it do
      brawl.deck_card_issues(deck).should match_array([
        "Deck contains Lightning Bolt which is not in the format",
        "Deck contains Sorcerous Spyglass which is banned",
        "Deck contains Black Lotus which is not in the format",
        "Deck contains 3 copies of Karn, the Great Creator, only up to 1 allowed",
        "Deck contains 2 copies of Ajani's Pridemate, only up to 1 allowed",
        "Deck contains 2 copies of Bulwark Giant, only up to 1 allowed",
      ])
    end
  end

  # Those methods already assume it is checked that:
  # * card is in format (legal or restricted) - by deck_card_issues
  # * there are 1 or 2 cards in sideboard - by deck_size_issues

  describe "deck_commander_issues" do
    let(:format) { FormatDuelCommander.new }

    it do
      format.deck_commander_issues(parse_decklist_for_commander()).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("7x Arcades, the Strategist")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("1x Arcades, the Strategist")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("1x Gideon Blackblade")).should match_array([
        "Gideon Blackblade is not a valid commander"
      ])
      format.deck_commander_issues(parse_decklist_for_commander("Sylvia Brightspear")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("Khorvath Brightflame", "Sylvia Brightspear")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("Khorvath Brightflame", "Karn, Silver Golem")).should match_array([
        "Karn, Silver Golem is not a valid partner card",
        "Khorvath Brightflame can only partner with Sylvia Brightspear",
      ])
      format.deck_commander_issues(parse_decklist_for_commander("Gorm the Great", "Rowan Kenrith")).should match_array([
        "Gorm the Great can only partner with Virtus the Veiled",
        "Rowan Kenrith can only partner with Will Kenrith",
      ])
    end
  end

  describe "deck_commander_issues" do
    # Lock time as it's a rotating format
    let(:format) { FormatBrawl.new(Date.parse("2019-07-01")) }

    it do
      format.deck_commander_issues(parse_decklist_for_commander()).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("7x Arcades, the Strategist")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("1x Arcades, the Strategist")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("1x Gideon Blackblade")).should be_empty

      # Never occurs in Brawl, but test anyway
      format.deck_commander_issues(parse_decklist_for_commander("Sylvia Brightspear")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("Khorvath Brightflame", "Sylvia Brightspear")).should be_empty
      format.deck_commander_issues(parse_decklist_for_commander("Khorvath Brightflame", "Karn, Silver Golem")).should match_array([
        "Karn, Silver Golem is not a valid partner card",
        "Khorvath Brightflame can only partner with Sylvia Brightspear",
      ])
      format.deck_commander_issues(parse_decklist_for_commander("Gorm the Great", "Rowan Kenrith")).should match_array([
        "Gorm the Great can only partner with Virtus the Veiled",
        "Rowan Kenrith can only partner with Will Kenrith",
      ])
    end
  end
end
