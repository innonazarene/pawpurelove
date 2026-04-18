import 'dart:math';

class PetQuotes {
  static final List<String> _part1 = [
    'A dog', 'A loyal companion', 'The pure heart of a pup', 'A wagging tail',
    'Every rescue dog', 'The deepest bond with a pet', 'A loving pet', 'Your furry best friend',
    'A little puppy', 'The soulful eyes of a dog', 'A dogs affection', 'The presence of a dog',
    'Walking with a dog', 'A tired dog', 'A playful pup', 'The love of a rescue',
    'A dogs loyalty', 'Every single bark', 'A wet nose', 'A sleeping puppy',
    'A gentle dog', 'The companionship we share', 'A furry friend', 'Your pup',
    'A devoted dog', 'An old dog', 'A young puppy', 'The spirit of a dog',
    'Your dogs trust', 'A four-legged friend'
  ];
  static final List<String> _part2 = [
    ' constantly teaches us about', ' endlessly reminds us of', ' simply provides',
    ' gives us a completely new perspective on', ' fills our lives with',
    ' beautifully demonstrates', ' is a constant source of', ' brings a feeling of',
    ' invites us to experience', ' is the ultimate proof of'
  ];
  static final List<String> _part3 = [
    ' unconditional love.', ' true joy.', ' absolute devotion.',
    ' inner peace.', ' unshakeable loyalty.', ' the beauty of the present moment.',
    ' unending happiness.', ' lasting friendship.', ' pure innocence.',
    ' lifes simplest pleasures.'
  ];

  static final List<String> _quotes = [
    "A dog is the only thing on earth that loves you more than he loves himself.",
    "Dogs do speak, but only to those who know how to listen.",
    "The journey of life is sweeter when traveled with a dog.",
    "A dog will teach you unconditional love. If you can have that in your life, things won't be too bad.",
    "Happiness is a warm puppy.",
    "No matter how little money and how few possessions you own, having a dog makes you rich.",
    "Everything I know, I learned from dogs.",
    "Love is a four-legged word.",
    "Life is a series of dogs.",
    "My little dog—a heartbeat at my feet.",
    "The world would be a nicer place if everyone had the ability to love as unconditionally as a dog.",
    "Dogs are not our whole life, but they make our lives whole.",
    "A dog's love is a pure thing.",
    "Those who teach us the most about humanity aren't always human.",
    "Be the person your dog thinks you are.",
    "Some of our greatest historical and artistic treasures we place with curators in museums; others we take for walks.",
    "When you look into a dog's eyes, you see a friend.",
    "You can't buy happiness, but you can rescue a dog, and that's kind of the same thing.",
    "Live. Laugh. Bark.",
    "Every dog has its day, and today is yours.",
    "Leave paw prints wherever you go.",
    "Dogs leave paw prints on our hearts.",
    "The best therapist has fur and four legs.",
    "A tired dog is a good dog.",
    "Home is where the dog hair is.",
    "Dogs are God's way of apologizing for your relatives.",
    "The road to my heart is paved with paw prints.",
    "Warning: I may randomly start talking about my dog.",
    "Life is short, play with your dog.",
    "A well-trained dog will make no attempt to share your lunch. He will just make you feel so guilty that you cannot enjoy it.",
    "Whoever said you can't buy happiness forgot little puppies.",
    "Dogs ask for so little but deserve so much.",
    "My dog is my favorite person.",
    "Treat every day like a walk in the park.",
    "A dog wags its tail with its heart.",
    "A bond with a dog is as lasting as the ties of this earth can ever be.",
    "Once you have had a wonderful dog, a life without one is a life diminished.",
    "Dogs own space and time.",
    "There is no psychiatrist in the world like a puppy licking your face.",
    "Blessed is the person who has earned the love of an old dog.",
    "Dogs just need you and love, that's all.",
    "Scratch a dog and you'll find a permanent job.",
    "Animals are such agreeable friends—they ask no questions; they pass no criticisms.",
    "Even the tiniest poodle is lionhearted, ready to do anything to defend home, master, and mistress.",
    "It's not the size of the dog in the fight, it's the size of the fight in the dog.",
    "No one appreciates the very special genius of your conversation as much as the dog does.",
    "You think dogs will not be in heaven? I tell you, they will be there long before any of us.",
    "We give dogs time we can spare, space we can spare, and love we can spare. And in return, dogs give us their all.",
    "There's just something about dogs that makes you feel good. You come home, they're thrilled to see you.",
    "To his dog, every man is Napoleon; hence the constant popularity of dogs.",
    "Dogs are wise. They crawl away into a quiet corner and lick their wounds and do not rejoin the world until they are whole once more.",
    "In times of joy, all of us wished we possessed a tail we could wag.",
    "Every puppy should have a boy.",
    "Properly trained, a man can be dog's best friend.",
    "I care not for a man's religion whose dog and cat are not the better for it.",
    "A house is not a home without a dog.",
    "Dogs are better than human beings because they know but do not tell.",
    "I have found that when you are deeply troubled, there are things you get from the silent devoted companionship of a dog that you can get from no other source.",
    "I think dogs are the most amazing creatures; they give unconditional love.",
    "You discover things about yourself you never knew you had when you have a dog.",
    "The dog is a gentleman; I hope to go to his heaven, not man's.",
    "Fall in love with a dog, and in many ways you enter a new orbit, a universe that features not just new colors but new rituals, new rules, a new way of experiencing attachment.",
    "Dog is God spelled backwards.",
    "Before you get a dog, you can't quite imagine what living with one might be like; afterward, you can't imagine living any other way.",
    "There is nothing more truer in this world than the love of a good dog.",
    "My dog thinks I'm a catch.",
    "If your dog doesn't like someone you probably shouldn't either.",
    "Money can buy you a fine dog, but only love can make him wag his tail.",
    "Petting, scratching, and cuddling a dog could be as soothing to the mind and heart as deep meditation.",
    "Dogs are our link to paradise.",
    "I work hard so my dog can have a better life.",
    "My fashion philosophy is, if you're not covered in dog hair, your life is empty.",
    "The greatest pleasure of a dog is that you may make a fool of yourself with him, and not only will he not scold you, but he will make a fool of himself, too.",
    "There are three faithful friends: an old wife, an old dog, and ready money.",
    "Dogs do not have many advantages over people, but one of them is extremely important: dogs do not talk about themselves.",
    "I love dogs. You always know what a dog is thinking.",
    "What do dogs do on their day off? Can't lie around – that's their job.",
    "Dogs are great. Bad dogs, if you can really call them that, are perhaps the greatest of them all.",
    "In order to really enjoy a dog, one doesn't merely try to train him to be semi-human. The point of it is to open oneself to the possibility of becoming partly a dog.",
    "Pugs are the best.",
    "Dogs look up to us. Cats look down on us. Pigs treat us as equals.",
    "If I have any beliefs about immortality, it is that certain dogs I have known will go to heaven, and very, very few persons.",
    "When an eighty-five pound mammal licks your tears away, then tries to sit on your lap, it's hard to feel sad.",
    "Dogs come into our lives to teach us about love, they depart to teach us about loss. A new dog never replaces an old dog, it merely expands the heart.",
    "I'm suspicious of people who don't like dogs, but I trust a dog when it doesn't like a person.",
    "The love of a dog is a pure thing. He gives you a trust which is total.",
    "No matter how you're feeling, a little dog gonna love you.",
    "Life changes when you get a dog.",
    "Dogs sit and listen when you want to talk.",
    "The better I get to know men, the more I find myself loving dogs.",
    "Dogs feel very strongly that they should always go with you in the car.",
    "Every day is a good day if you spend it with your dog.",
    "The only fault a dog has is their short life span.",
    "It's hard to be sad when you're greeted by a wagging tail.",
    "Take time to pause and enjoy the little things, just like your dog does.",
    "A sleepy dog is the picture of peace.",
    "Listen to your dog: eat well, rest well, and play often.",
    "If you want the best seat in the house, you'll have to move the dog.",
    "First they steal your heart, then they steal your bed.",
    "Enjoy the journey with your faithful companion."
  ];

  static String getRandomQuote() {
    final random = Random();
    // 50% chance to use a standard quote, 50% chance to generate one of 3000 dynamic quotes
    if (random.nextBool()) {
      return _quotes[random.nextInt(_quotes.length)];
    } else {
      final p1 = _part1[random.nextInt(_part1.length)];
      final p2 = _part2[random.nextInt(_part2.length)];
      final p3 = _part3[random.nextInt(_part3.length)];
      return '$p1$p2$p3';
    }
  }
}
