SUITS = ['H', 'D', 'C', 'S']
VALUES = ['7', '8', '9', '10', 'J', 'Q', 'K', 'A']

class Card:
    def __init__(self, suit, value):
        assert suit in SUITS, "Invalid suit"
        assert value in VALUES, "Invalid value"
        self.suit = suit
        self.value = value

    def __repr__(self):
        return f"{self.value}{self.suit}"

class Agent:
    def __init__(self, hand):
        # hand is a list of Card objects
        self.hand = hand
        self.trump_suit = None
        self.current_suit = None

    def set_trump_suit(self, trump_suit):
        assert trump_suit in SUITS, "Invalid trump suit"
        self.trump_suit = trump_suit

    def play_card(self, current_suit, cards_on_table):
        # Get valid cards to play
        valid_cards = [card for card in self.hand if card.suit == current_suit]
        if not valid_cards:
            # If no cards of the current suit, play any card
            valid_cards = self.hand

        self.current_suit = current_suit
        # Choose the best card (highest value)
        best_card = max(valid_cards, key= self._card_to_val)
        # Remove the card from hand
        self.hand.remove(best_card)
        return best_card

    def _card_to_val(self, card):
        if card.suit == self.trump_suit:
            return VALUES.index(card.value) + 8
        elif card.suit == self.current_suit:
            return VALUES.index(card.value) + 16

        return VALUES.index(card.value)

# Example usage:
hand = [Card('H', '7'), Card('D', 'A'), Card('C', '10')]
agent = Agent(hand)
agent.set_trump_suit(input("Enter trump suit: ").upper())

def play_hand():
    current_suit = input("Enter current suit - ").upper()
    cards_on_table = [Card('H', '9'), Card('H', '10')]
    card_to_play = agent.play_card(current_suit, cards_on_table)
    print(f"Agent plays: {card_to_play}")

# while True:
#     play_round()

