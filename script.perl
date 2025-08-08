#!/usr/bin/env perl
use strict;
use warnings;
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::Atom::Person;
use DateTime;
use DateTime::Format::RFC3339;
srand;
# https://metacpan.org/pod/XML::Atom::Feed
# https://metacpan.org/pod/DateTime

# using atom instead of rss because rss is poorly-formed/ambigious/bad iirc
# some reminders on atom feed spec,
# via https://www.ietf.org/rfc/rfc4287.txt:
# - atom feed filled with atom entries
# - either feed has an author, or all entries have an author (which in turn must have a name)
# - feed entity must also have id, title, and updated
# - feed entity should have a link rel=self (i think?)
# - entry must have id, title, updated
# - entry should have a content entity
# - content type = either text, html, or xhtml; default is text 
# - text type should be plaintext, human-readable; whitespace may be collapsed by consumer
# - html type should be escaped html, ready to render in a div, like &amp;
# - dates(datetimes) conform to rfc3339
# - ids conform to rfc3987 (internationalized URIs) (which means unique URL, probably)
#
# example feed from spec:
#
# <?xml version="1.0" encoding="utf-8"?>
# <feed xmlns="http://www.w3.org/2005/Atom">
#   <title>Example Feed</title>
#   <link href="http://example.org/"/>
#   <updated>2003-12-13T18:30:02Z</updated>
#   <author>
#     <name>John Doe</name>
#   </author>
#   <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>
#   <entry>
#     <title>Atom-Powered Robots Run Amok</title>
#     <link href="http://example.org/2003/12/13/atom03"/>
#     <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
#     <updated>2003-12-13T18:30:02Z</updated>
#     <summary>Some text.</summary>
#   </entry>
# </feed>
#
# example feed for this project:
#
# <?xml version="1.0" encoding="UTF-8"?>
# <feed xmlns="http://www.w3.org/2005/Atom">
#   <title>some title</title>
#   <subtitle>some subtitle</subtitle>
#   <id>some id</id>
#   <link/>
#   <updated>some timestamps</updated>
#   <author>
#     <name>some author</name>
#   </author>
#   <entry>
#     <title>some title</title>
#     <id>another id</id>
#     <updated>another timestamp</updated>
#     <content type="html">
#       some content &lt;br&gt;
#     </content>
#   </entry>
# </feed>

$XML::Atom::DefaultVersion = "1.0";

my $FEED_FILE = 'feed.xml';
my %FEED_METADATA = (
    title => 'escarp.org drip feed',
    subtitle => 'nuggets of poetry',
    feed_uri => 'https://github.com/wong-justin/escarp-drip/',
    link => 'https://github.com/wong-justin/escarp-drip/',
    author_name => 'various tweeters',
);

sub write_file {
    my ($filename, $content) = @_;
    open my $fh, '>', $filename or die "Cannot write $filename: $!";
    print $fh $content;
    close $fh;
}

my @poems = (
    "Dusk//\n\nIn the early/ \nevening, brown/\nglows/\nlike neon.  Faces/ \nare lost/\nin the scuffle/\nbetween light and dark.//\n-- \@jrcripe",
    "Kamikaze Pilot//\n\nWhen I came home/\nI didn't get/\na hero's welcome.\n-- \@EdmundConti",
    "Sweet corn for supper/\nGrinning/\nFrom ear to ear.//\n-- \@EdmundConti",
    "The man on the street hacks a coconut with a machete, hands it to her with a straw and a smile, his life a novelty for her soft, pale ha ...",
    "The warmth of her embrace transcends her steel skull, nylo-gelatin skin, copper arteries. Together we are more than human. // \@gryphoness",
    "Love Poem//\nSometimes my shirt makes sparks. Watch me take it off. //\n\@jpoch",
    "old astronauts/\nyearn for space, unable/\nto relate to earth //\n\@wordshiv",
    "Paul Gardner serves beer in ceramic dishes, spilling foam all over the bed. He toasts Rose: Your health, and death to snails.//\n\@jsgraustein",
    "The universe stopped expanding and started to pull back into itself. After the thaw, Henry noticed there were dinosaurs again. // \@wordshiv",
    "i prayed to the patron saint of sheep; i dreamt of cinnamon & spices from far-off lands; i walked on sunshine & brushed clouds from my e ...",
    "Departing, I watch the sun expand, consuming planets like Cronus eating his young. What Zeus has left these stones in his stead? \@hdgrogan",
    "The job/\nof the sky/\nis to be blue./\nHow much/\ndoes it pay?\n\@m_purdy",
    "Each snowflake unique/\nCrystalline iterations/\nSparkle as they die\n\@StephenDRogers",
    "\"You're wasting music,\" my parents said. I turned off the radio and listened to branches scraping the house, forks tapping plates. \@m_purdy",
    "Non-violent protesters jailed for life. Fascist state feeds and clothes them: socialism creeps in, a hesitant embrace.\n\@q8p",
    "We throw a body off the ship and his fellows follow in a macabre necklace. Begging hands snatch my ankle as they rush by.\n\@lastlittlebird",
    "In the brownstone, a couple fighting in the tub soaks the floor. Their laughter runs into the drip of your ceiling.\n\@joannemerriam",
    "As my friend told me about Peak Oil, my tongue fretted the crack in my bottom left molar. I nodded and took another sip of my coke.\n\@m_purdy",
    "vile hissing possum /\nlost traction on its entrails /\ncan’t outrun my car\n\@bethblackbird",
    "he is a fishnet jobbing as a windsock/ corkboard bobbing, hoping the sea opens/ unmoored, he says send me a storm for a doorway \@jeremylewit",
    "No one hates the Beatles as much as the guy calling numbers at the DMV. \"Number eight,\" he says, then grimaces. \@m_purdy",
    "I roll your words around my mouth/\nLike a plum/\nTaste them. \@amgamble",
    "He sleeps so hard he looks dead. Then he sighs, unaware of the seizure of love and fear aroused in the quiet. I fold more laundry.\n\@amgamble",
    "Watching a woodpecker go at our shed with such gusto, I didn't have the heart to tell him it was aluminum. \@bethblackbird",
    "He is my charge. My long fuse, my ominous weather report. Nocturne, shiver. Sailboat on a moon river. \@rubychristine",
    "A great business plan/\nYou pay me to ram, scrape, wreck/\nBad drivers near you\n\@michelleshy",
    "A great business plan/\nCartoon character condoms/\nThat talk like puppets/\n\@michelleshy",
    "Charon trawls the internet for discarded avatars. Small, surplus lives, flotsam of the electronic sea. \n\@deboree",
    "She marked out \"susurrated\" and sent the article back. \"We're not writing for wine drinkers. And I want to see your receipts.\"\n\@amgamble",
    "I pulled the alarm as a joke. I didn't know about the real fire, but no one believed me. My school needed a hero, not a clown. \n\@MinikinMath",
    "Ever since the Church replaced the Blood of Christ with the Extract of Opium, reported Visions of Mary became ever so glorious.\n\@UriGrey",
    "My private motorway, from childhood football after construction to arrival at Wigan homeward bound, clear route past roundabout town\n\@dradny",
    "Watford Gap verge through coffee steam/\nhum of traffic noise/\nknowing we are an hour away - the beauty of the service station\n\@dradny",
    "Are trees offended standing/\nby telephone poles? Do they aspire/\nto charged practicality? \@FissionaryPoet",
    "When she met him, the rain stopped, the clouds parted and the sun shone once more. The drought lasted the rest of her life. \@jonpinnock",
    "A train whistle slips through the rain. Your memory Dopplers into my past. I bleed coffee and update a pie chart. \@blueberrio",
    "She said she was out of my league. So I asked: \"What about a cup-tie?\" Really, I should have seen the penalty kick coming. \@synthjock",
    "One hundred thousand/\nTransparent hairs on your face/\nBlotting salt-hot tears/\n\@michelleshy",
    "Hollow gingerbread man, licorice lace innards, prune heart. In the head, a cookie fortune. It pounds the inside of the oven door. \@xalieri",
    "'I don't want my funeral to be a sombre occasion,' Dad used to say. To this end he split his fortune between six mistresses. \@synthjock",
    "We remember her with plastic roses thrown into the refuse of the Pacific.  Her husband drinks in New York with his mistress. \@skyllairae",
    "she left her makeup smudged when she headed out to meet him for lunch. it wouldn't have felt honest otherwise \@elle_wrathall",
    "\"People who don't trust others are untrustworthy,\" says a boy carving ice. I drink fake cocoa and ask, \"How would we know?\" \@blueberrio",
    "The merciless bride smiles at the reception line. Festivities are planned. Then he'll be all hers for the night. For life. \@blueberrio",
    "Obama backwards is amabo, in Latin, \"I will love.\" So forwards must be: \"They have hated.\" Some are still stuck in the imperfect. \@m_purdy",
    "the gas-pedal gauged her frustration at the gloom. she drove recklessly on days like these, as though she were chasing Spring \@elle_wrathall",
    "Roasting in sun-view, suit holed, air all but gone, Zak craves grass between his toes. Facing home, he's dying to feel rain. \@OscarWindsor",
    "Firing coloured explosives from the dock, looking into the sky. You kiss me. I hit you back. Our combustible ritual, every year. \@blueberrio",
    "He tosses out her bottles of omega-3, antioxidants, and zinc, wondering why she didn't buckle up. \@iwantanewhead",
    "Once upon a time, a boy immolated a frog. His parents found him face down in the pond the next day, not a frog in sight. \@prav_us",
    "\"i still don't get it. what's a metaphor?\" the student mumbled. she paused, but then said it, \"when you call me puta.\" \@elle_wrathall",
    "She could see everything: sunshine behind the windowpane, birches in a cluster, even the mental institution's pond frogs. \@skyllairae",
    "How I know to trust her://\n\nHere, she says, try this. /\nI put out my hand/\nand she offers me sunlight. \n\@benmiller314",
    "In the beginning was the Word,/\nand through a fine fissure of an \"L\"/  \nour world gushed forth/ \nin all its goddamn splendor.\n\@micoquente",
    "\"If your critique doesn't hurt, it can't help me learn and grow,\" I said. \"Then we should have a safety word,\" she replied. \@boudreaufreret",
    "After his team's defeat he prowled home all geared up to murder something. She read the signs and prepared a sacrificial beer.\n\@synthjock",
    "alternative school/\nteens deboard the bus like quail/\nall over the street/\n\@kristinamaupin",
    "I passed the cancer wing smelling of smoke and saw a picture of a dead friend. No ashtrays anywhere, so I moved on.\n\@duncanmurrell",
    "if pain had volume/\ncould it fit in the body?/\nwould we be neutron stars/\nthree suns' sorrow/\nin the space of a beating fist?\n\@gruntleme",
    "He tells himself Greed would have kept the goose, content with the golden eggs. It took Science to vivisect her. \@iwantanewhead",
    "When our son kills himself: dismayed. When our daughter follows suit: perplexed. Perhaps kids need rooms with windows after all. \@NGodSavage",
    "A nation's on his shoulders, breathless at the gasp of his blades. His wrist snaps; the light shines red; a country's lungs roar. \@rwohan",
    "Bird watcher/\nused to be/\ngirl watcher/\nbut they never/\nwhistled back\n\@wordshiv",
    "After The Bomb Went Off//\ncurling wisps rise from/\na robust cup of coffee/\ncooling for no one/\n\@ianweiqiang",
    "i believed you/\nbut you added/\n\"Honestly.\"//\nand i saw unfaithful sheets/\nheard polygamous whispers/\nsmelled deceitful pheromones/\n\@x96pkn",
    "Once there was a man who was afraid of his shadow. Then he met it. Now he glows in the dark. \@benloory",
    "Before the stick dried, I knew she was pregnant when the bones in her foot suddenly radiated like tree roots through dark soil. \@msrpog",
    "The fire left a stench of smoldering flesh. He'd raged inside, an animal, my love. The door was nailed solid. I knew; I did it. \@jacbateman",
    "Spring Cleaning//\neach sweep of the broom/\nbrings the floor one tile closer/\nto how she saw it/\n\@ianweiqiang",
    "White noise of the ocean,/\noverwhelm my hesitation;/\navalanche down my shoulders/\nto my feet,/\nlure me/\nto the plunge./\n\@LBelowtheauthor",
    "Domesday Tweet//\n\nThe last fruit from the Tree of Life/\npicked, weighed and DNAed,/\ngraced Kew Garden’s Eden Landscape./\n\@stellapierides",
    "I lived to touch you/\nSo we could contest the stillness of my walls/\nWhich hadn't felt the quake of life in years/\n\@latinegra",
    "Troubled water churns my eyes, as night's last sights flash. I'm like ash, crashing in brain-waves. I fly half-mast. \@JohnBlakeWolf",
    "She brushes her fingers over the dedication page, but can't feel her name. \@FadedPaper",
    "Excited to surprise his Internet girlfriend, he grips airport roses and knocks. \"It's complicated,\" says the guy who answers. \@blueberrio",
    "Parking Lot Pacing//\n\nEvery withered, wet/ \npalm branch is a pale,/\ndead bird, mangled./\n\@danielleblasko",
    "Sketch//\nCobbled lanes lead downhill/\nto the bowels of the old city/\nwhere the Abbey standing still/\nsets a Zone of Silence.\n\@stellapierides",
    "atonal (haiku). coincidence is just a song you sing when you've otherwise lost tune. \@josephquintela",
    "With the carcass buried/\nin a single turn of earth/\nI honor a noble life/\nwell spent/\nnever thinking of mouse traps./\n\@apoetseye",
    "She tucked a rock of crack into her accordion and crushed a cockroach with a heel, ready to stare those men in the eyes again. \@blueberrio",
    "Dear GPS of my soul,/\nKeep me going straight/\nDown this cul de sac./\nIt once ended in a footpath/\nWhere one could get lost./\n\@stevencrandell",
    "Trains full of/\ncoal, rearing/\nin the deepest/\nparts of night./\nHonking out/\ntheir existence,/\neach boxcar/\nits own swan./\n\@SusanScarlata",
    "HUNG SHOES//\n\nLike unleavened bread/\nflatly there. Proving/ \nthe tightrope, the pull,/  \nall that can be/ \nhurled up into./\n\@SusanScarlata",
    "A Prayer//\n\nMay we change like the water,/\nReceive like the earth,/\nWander like the wind,/\nNurture like the light./\n\@stevencrandell",
    "The farmer/\nslips from the wadi/\nby starlight//\n\nhe stops along the road/\nleading into town//\n\nseeds of fire/\nburst open/\nat dawn\n\@mswriting",
    "In the Kitchen//\n\nThe womb is a bowl/\nfilled with water/\nand kibble. She puts/\nthe womb in a cage,/\nfeeds the unconscious./\n\@danielleblasko",
    "At the Cornmill Meadows/\ndragonflies rest on nettles/\ncomfrey, buttercups/\nand the smooth stones/\nof the shallow stream./\n\@stellapierides",
    "After The Bomb Went Off VI//\nantennae twitching/\nthe meek venture forth into/\ntheir new-made Eden/\n\@ianweiqiang",
    "Another guy picks up his latte, and I slip the valentine back into my\npocket. The barista draws crema hearts for everyone. \@ShelbySDavis",
    "Salt is a natural/\nantiseptic. That's why/\nwe rub it in our wounds./\n\@JamesCihlar",
    "Loss hollowed him like a gourd./\nWhen he laughed,/\nOld seeds rang within./\n\@stevencrandell",
    "Longer Half of the L//\n \nMay loneliness leave only lovely long lawns after./\nMay this green's light leaves lift to rafters laughter./\n\@jpoch",
    "One Sound, One World/\nBig, tough fella/\nloud, racy lass/\ntimid Cinderella/\nprodigy, alas/\nblow your vuvuzela/\nif you must./\n\@stellapierides",
    "Sleet sweeps the hills. Houses fold into mudslides. A cat climbs my limbs and I become her tree in the flood. Strays, we cuddle. \@blueberrio",
    "Warm breeze/\npatrols the streets/\nparking tickets/\nflutter/\n\@wordshiv",
    "Red-winged blackbirds flock, a convention of male epaulets. The boss says, her shoulders burning, \"The pond goes.\" \@Shannon_Anthony",
    "Life is a near-death experience/\nAncestors sing in my spine/\nOffspring give shape to memory/\nMemory gives shape to time/\n\@stevencrandell",
    "Inhaling deeply/\nI gather myself/\nLike the tines of a zipper./\n\@LBelowtheauthor",
    "By night he'd take her by the hand and, as in their youth, go smoke pot under the bridge. By day, they were grandpa and grandma. \@3tdoanVSS",
    "The Frisian lands lying flat/\nopen up to infinite skies/\nlet the moon-pulled tides/\ncarve rivulets of love/\nin the sand./\n\@stellapierides",
    "He shuts out the cold Sutton wind whistling off the creek, and locks in colder quiet. \@FadedPaper",
    "Stars//\n\nHere under all these/\nindifferent nuclear storms,/\nhere only, sings love./\n\@robertwest7",
    "Murnau//\n\nBlue, stone haystacks,/\nthe Alps,/\ncradling the moor,/\nfeed warm light/\nto wild orchids,/\nmake their colors sing./\n\@stellapierides",
    "A mother shouts./\nHer toddler freezes, halfway across the street./\nSlamming on the brakes,/\nI am both./\n\@stevencrandell",
    "Good Night//\n\nOutside, the old dog/\nbarks his elaborate rhymes,/\ndefying the dark./\n\@robertwest7",
    "Build mansions here inside me. Take risks in home decor. Shingle rooves but leave the skylights open. Never lock the doors. \@JMPrescott",
    "Reverie//\n\nver her hands running/\nthrough and gathering up her/\nhair over and o/\n\@robertwest7",
    "In the tired gray gloaming of light-polluted modern life even the fastest train cannot carry you where you need to go: to sleep. \@montsamu",
    "Oculus//\n\nHeadlights/\nreveal the chase/\nin two flashes:  the deer/\nruns for its life, but so does/\nthe wolf./\n\@DawnManning23",
    "from inner space/\nsyncopated prophets blow their crazy angles of paint/\nlike jackie mclean with a syringe full of sparrows/\n\@PsychicMeatloaf",
    "Near the end, Themistocles dreamt the taste of hemlock was brine, his heartbeat a trireme's oars as it scribed the wine-dark sea. \@DennisYG",
    "your sunlight/\nsways through trees/\nlike delicate bones of wheat/\n\@PsychicMeatloaf",
    "Zero Balance//\n\nNothing's harder to imagine/\nthan nothing;//\n\nlately, most of us/\ncouldn't draw a blank//\n\nif we tried./\n\@robertwest7",
    "Seen on a Run//\n\nPost-lactation/\nunsheathed in lycra/\nFallen like me/\nNo longer,/\nI imagine,/\ntoo tender to touch/\n\@stevencrandell",
    "Sole Survivor//\n\nIndian summer,/\nbrown oaks and naked maples--/\nlast katydid rasps./\n\@oldmanscanlon",
    "Perspective is truth./\nTruth, perspective./\nEven the line at the horizon bends/\nGiven space./\n\@stevencrandell",
    "Poor matryoshka,/\nburdened with one inner life/\nafter another./\n\@robertwest7",
    "Cassette tape strewn in roadside grass/\nGleams like snail-paths in the moonlight./\n\@ShelbySDavis",
    "Battle's smoke spiraled up, reminding William of a cook fire, the screaming sizzle of meat fat releasing its juice; to which God? \@svramey",
    "Bars, Hold Me In//\n\nCaged animals--their heat/\ntheir wild eyes, bared teeth/\nI want to live inside their breasts,/\nbeating./\n\@amyjosprague",
    "Morning/\nwhen I lift blinds to light your empty room/\nI dream groves of incense trees snow dusted/\non red hills in old Morocco./\n\@2kurtryder",
    "The gardener struggles with a hose, his berry-stained basket nearly empty. The fruit--what wasn't stolen--was ripe. \@blueberrio",
    "Winter rain, bare feet/\nPuddles wide and ankle-deep/\nOpportunity/\n\@stevencrandell",
    "Pond half-frozen/\ntwo geese, many ducks, wind easterly/\nyesterday's ballerina tests ice/\ntiptoes/\nlegend kept bright./\n\@2kurtryder",
    "silent weir:/\nswans glide across/\na cloud./\n\@stellapierides",
    "dusk epiphany--/\nyou're the mosquito's/\nreligious experience/\n\@joannemerriam",
    "Lend yourself again to music/\nmake pepper pot, pour wine/ \ntoss away the bleached bare bones/\non which your famine dined./\n\@2kurtryder",
    "Garlic Love//\n\nAt first/\nthe layers come loose with ease--/\nshedding/\nrevealing/\ntaking wing/\n\@stevencrandell",
    "Youth//\n\nmoan woven shrieks/\nbellowed at dusk;/\nwe were furless/\nwerewolves crying/\nfor the moon./\n\@CjakMussington",
    "Lawnmower//\n\nAngriest herbivore,/\ngo ahead, roar//\n\nas you graze/\nsummer days://\n\nyou and the weather/\nwill cool off together./\n\@robertwest7",
    "DEW//\n\nStep lightly as the sun/\nwakes up//\n\nand the other stars all/\nfall asleep//\n\nin the grass./\n\@robertwest7",
    "Moon sits on gravel road in Lotus Pose/\nI dare myself/\nGet close to his face/\n\@michelleShy",
    "We had an apocalypse fling, but once the grid powered up she left me for a reconstruction job. Now I tend tumours in her place. \@blueberrio",
    "The bus driver reminds me of my dad, his forearms old and mangled like nicked table legs. I miss my stop to keep him company. \@air_GO",
    "Ripen to black/\nMy emerald knobbiness/\nMy Hass/\nLet my gentle touch/\nDiscover your firm yielding./\n\@stevencrandell",
    "Sometimes instead of love you make cookies. Sweet, understand: butter and brown sugar are part of the argument for leaving. \@gruntleme",
    "He tapes an ice cream poster to his van, plays music out the window. Kids run up for treats on ice. Some of them, he eats. \@SusanRukeyser",
    "Come in and loosen your tie/\nundress before the long wide world./\nYou are 30 floors up;/\nthe skyline is paid for./\n\@Bendied",
    "A woman grew in Jim's garden, her hair pale as cornsilk. And softer. After they woke, she trickled salt in the space she came from. \@cerulae",
    "She held as if we had no skin,/\nher spoke-thin bones/\nclenched to mine./\nSometimes rain grips the trees/\nlike this./\n\@cerulae",
    "dandelion cracked sidewalk left-wild spaces \@joannemerriam",
    "Our blood unbluing (lung-/\nsung red) circles/\nour centers, Ptolemaic.//\n\nLet ellipses throb/\ntheir galaxies between us./\n\@cerulae",
    "In the wet rainforest of the third apocalypse, the only dry tinder is her literary past. She chooses death. Mold eats the paper. \@blueberrio",
    "Coconut kefir, sour cream,/\nKraut, kvass, pickles, yoghurt and kimchi./\nIn tall, glass jars at home,/\nLove ferments. \@stevencrandell",
    "glacial/\nthe silence of space/\nagainst glass/\n\@stellapierides",
    "Rain, sweat bead on my skin/\nI am a marvel/\nWaterproof and porous/\nOpen and immune/\nSteam rises from my hands/\nLike a prayer\n\@stevencrandell",
    "My daughter saw it first/\nHer brother's helium birthday balloons/\nCasting stained-glass shadows on the sidewalk/\n\@stevencrandell",
    "He collected broken cameras, and showed them to his date. These are my hearts, he joked, tapping one of them with a light hand. \@20Limes",
    "After the yelling, I hid every spoon we had. At dinner, we sipped tomato soup off forks. The next day, I learned to hide the belts. \@cerulae",
    "Old newspapers littered our mother's coffee table, their crosswords half finished: a farewell letter in fractured answers. \@andrewcothren",
    "One-thirty a.m.:/\nbirds are singing in the dark./\nO my fellow fools./\n\@robertwest7",
    "What keeps us upright if not the moon? That white knuckle beckoning--our bodies, heavy as oceans, salt washed up on the skin. \@DawnManning23",
    "naked tree silhouetted against a stratified sky, fading from stars to morning light \@FrancesMRoth",
    "War Photo #13: Out of its artillery wound, the German house sings a raspy Tchaikovsky. \@DanielKovalcik",
    "War Photo #19: With her tiny Asiatic fingertips, a woman explores the moon-sized bandage she has for a head. \@DanielKovalcik",
    "REFLECTION//\n\nA clouded-over sky/\nstill shines/\nin a clear eye./\n\@robertwest7",
    "The President takes the baby from its mom. She hurls it into the air. It explodes, showering her with ticker tape. \@Markywriter",
    "Look up, black and tangled fingers, tracing constellations across a pink sky, a mother's silken hands cradling the moon. \@FrancesMRoth",
    "We stood above the highway, taillights like rubies on the curve of a neck. The city a gift you gave me, one I wouldn't wear. \@mainewriter",
    "People too have hands and faces. The clockmaker knew what made them tick. \"One question,\" he said feeling my face. \"Got the time?\" \@J3xf",
    "Stumbling heartbeat, a moth's wing striking a live bulb in code--the heat whisper of tissue fusing to glass. \@lhstaubs",
    "O, pristine new mansion! Bloated, redundant. Birds shit your roof too. Termites plot invasion. Beneath, patient worms squirm. \@SusanRukeyser",
    "Weave opium poppies through a cracked spine/\nPluck every tendon like harp string/\n\@fvnck",
    "in a dream/\nI ask the man with the ladder/\nto climb higher/\nmy braids have come loose/\nand I want something new/\nto weave.\n\@Phoepee",
    "I was told your diagnosis before your name/\nWe met/\nAnd discussed the weather/\nI sent an amaryllis to brighten your deathbed.\n\@laurieajacobs",
    "The thing about spring/\nlilacs and the daffodils/\ncome later. First, death./\nWhat didn't die last year/\nfinishes itself off./\n\@marcoanders",
    "planes take off/\njust seven miles down the road/\nbut hundreds of miles deep into memory/\nof all the somewheres far away/\n\@stephxRED",
    "Old skins, shedding, fill train seats with bones, warm, still here./\nRed lipstick bleeds more at last stops. All passengers depart./\n\@hayhud",
    "ULYSSES - Ever frailer / bound for failure / die at sea or home // I roam\n\@robertwest7",
    "My father licks the tips of his antlers, straps them on. \"You're not a man 'til you wound me.\" \@iheartfailure",
    "love was grey, I thought,/\nan in-between,/\nwhere the wise monk & foolish beggar in us/\npress together,/\nfuse./\n\@JRYussuf",
    "Goodbye, grasshopper!/\nMockingbird's meal, remember:/\nyou died for song's sake./\n\@robertwest7",
    "I travel a black tunnel:/\nthe pupil of a cat's eye narrowing -/\ncircle to almond to line -/\nblack to let in light./\n\@stevencrandell",
    "Between days she sleeps fitfully in summer heat, her dreams parched as parks. She downs tequila for rainstorm nightmares. \@blueberrio",
    "with windows down, at 30 mph,/\nshe's less lonely. the wind moves through her/\nhair the way his fingers used to./\n\@RLussos",
    "Fetish becomes ritual with the Glock hidden beneath her pillow. \n\@dlshirey",
    "I hid you in my palms/\nso as to mold you, leave/\nmy life and love/\nlines against your back,/\nyour spine breaded with my skin./\n\@scoopsscoops",
    "France/\n\nThe dead compose/\nIn Beaujolais./\n\@bri_clements",
    "Water slips on fin. Round eyes shine. An urge, a strike. Blood flows like smoke. My waves were tiny, I dreamed I was safe. \@triciababydoll2",
    "Strangers sit by the stage, sweat under a setting sun. The sound system stops. Swapping whispers, their lips share Shakespeare. \@anandalima",
    "RECOVERY/\n\nThe moment when/\nthe water turns/\nfrom tepid to cold/\nat the tap:/\ntomorrow, too,/\nwill come./\n\@RGEvans",
    "SEA OF TREES/\nWhat restrains me/\nfrom warping the loom of the wind?/\nMy toes dare the weft-/\ntrees, branches woven/\nwith limbs./ \@MDunbarFox",
    "Teaching in Japan--lunch with boss--food slips from chopsticks; hits floor. I rush to clean, \"Let nature,\" my new friend says. \@BAMWrites",
    "I dream a bear carries us through the forest on his back. We cling to his fur, he wants to bury us in a storyteller’s throat. \@traversjul",
    "Brown and dry and letting go, trees scatter meat for worms. Water pours from smoking skies, yet nothing drinks. Everyone's asleep. \@Lyridae",
    "Clouds churn, winds bleed, stars burst, waters pour. Wet feet slip in clay. Calm. Indian blankets open, I wake. We kiss blue skies. \@Lyridae",
    "HOLLOW WASPS\nfull of red wine-/\nblown glass, feet/\nlike delicate icicles./\nNot locusts, no rasp./\nA fragile buzz. Sip, unstung./\@blueaisling",
    "The night Mom died, Dad and I bought fried chicken on the way home from the hospital. We ate, stared at bones, silent. \@Alex_Z_Salinas",
    "Requiem for a Neighbor Two Doors Down/\n\nHandwritten condolences/\nwave hello, dislodging/\nold flirtations lugging grocery bags./ \@girlinblack",
    "We were putting up groceries when she said, You'll love again. I said, Baby, you'll fight this. Mmhm, she said, and smiled. \@Alex_Z_Salinas",
    "Eventually you'll feel guilty. I'll back away in the corner and watch blood dribble from your smile. Only I will know. \@_RobinJohnson",
    "Moonlight slanted through the curtains in a new way. She wondered which had tilted, the world or her own meridian. \@SarahVernetti",
    "Before you leave,/\nyou lean in close./\nMy beard against your collar/\nsounds like shoveling snow./\n\@MarcoAnders",
    "As his pod hurtled over the event horizon, he hoped for a swift, specific death; his ex never believed in Hawking radiation. \@crownofpetals",
    "Spider leg eyelashes tickle the tops of cheeks, stretch, wrap around the neck. Wake up screaming, gasp for breath. \@_RobinJohnson",
    "She tried to vary routine, anxious. It wasn't easy to substitute oysters for chicken. It didn't always work. She ate it all. \@blueberrio",
    "I said sorry but hoped I'd done more damage. The dangerous space in your V-neck teases, a target to lick. \@_RobinJohnson",
    "Flies unspooled from the drain into my mouth, knitting a blanket of protection, a winged collection too big to spit out. \@_RobinJohnson",
    "She's tired as a sick spider,/\nbut the basket must be lowered,/\nthe melon placed therein,/\nand the hope of the world preserved./\@ajackson568",
    "Refugee Camp, 1948/\n\nI remember only a little/\nthe grayness of everything/\nand how silently/\nmy mother wept./\n\@johnguzlowski",
    "Beyond the smoke, an arrowhead of birds pierces stacks of cumulus. Fire threads along treetops. The earth continues to burn. \@OliviaKCerrone",
    "My mother barbecued a moose in Yiddish, needing no heat but her grilling tongue. \@ajackson568",
    "It's the first day of bear tickling season. Game wardens prowl the forest, issuing citations for not saying \"coochie coo.\" \@CalebEchterling",
    "No Man is an Island/\nOr a mountain/\nA tree or a forest//\n\nHe's just a Popsicle/\nMelting fast or slow//\n\nBut always melting./\n\@johnguzlowski",
    "I walk in morning's dark/\nBefore moonset and sunrise/\nNo surfers, one fisherman/\non the pier, no waiting/\nfor cars at the light.\n\@madeline40",
    "DEMISE/\nI will not die well. Bidden, cars will crash into cars, an orchestrated wall of steel and, well, my death./\n\@ParticleFiction",
    "Lonely asteroid seeks caring planet to orbit. Promises regular meteor shows, added features to eclipses and no GPS disturbances. \@RxHemmell",
    "Despite her distant tinny voice in the luminous clamshell phone booth, and the pounding surf, he missed her. \@JISimpson",
    "Apiary's ransacked, almond trees won't get pollinated. Creaky creased beekeeper putters past hives, wondering how much he has left. \@nwi_jsp",
    "The hawk sees through the speed of light,/\nflies my garden birds to heaven on steel wings./\n\@JoyAnneODonnell",
    "It's rain/and the pollen's beat/down, put to bed/for the night/now's your chance/for so long/you've been the one/washed out  \@NoahRenn",
    "Pencils scratch in circles,/ convert standardized tests to waveform,/ but Helen's hair silently/ grazes my desk. \@fcmwrite",
    "He took an old pizza box to a place where the trees couldn't tell him anything and wrote, \"Recycle\" in fresh, local urine. \@haunted4always",
    "Flames reflect in my wine glass, alive and rhythmic. Above the fireplace, you sit. Still. Quiet. Are you warm? \@_RobinJohnson",
    "They left the parking lot: she to another man, he to an empty condo. Their kiss lasted hours: her silence after, much longer. \@Alex_Z_Salinas",
    "Mosquitoes land on my chest. Dry for months. But little legs, mouths, search for blood. \@_RobinJohnson",
    "Grief is rotting fruit but you are starving/\nsalt-bitter skin/\nand inside/\ndry seeds/\n\n\@austinsively",
    "her shadow forms depressions/\nat the bottom of the door/\nall along our baseboards/\nthe floor grows black/\nas she turns on the dark/\n\n\@fcmwrite",
    "darkness will go/\nwhere the light/\nrefuses/\n\@bobcarlton3",
    "The ladies with feather tails glide up the escalator over Las Vegas Boulevard. They talk shop, feathers dusty and nylons clean. \@anikeaten",
    "most nights, the moonlight/\noutlines all the shadows scattered outside,/\neven those within/\n\@fcmwrite",
    "old dog/\nher ailing heart beats/\nagainst my leg/\n\@witnwords1",
);

sub generate_feed {
    my $now = DateTime->now();
    my $now_formatted = DateTime::Format::RFC3339->format_datetime($now);

    my $old_feed = XML::Atom::Feed->new($FEED_FILE);
    my @old_entries = $old_feed->entries;
    my $old_identifier = $old_entries[0]->id;
    my $then_formatted = $old_entries[0]->updated;
    my $then = DateTime::Format::RFC3339->parse_datetime($then_formatted);
    my $delta = $now->delta_days($then);
    my $days_elapsed = $delta->in_units('days');
    if ($days_elapsed < int(rand(7)) + 1) {
            # perhaps millisecond inaccuracies will skip a day, but oh well
            # there's always tomorrow
            die "no poem today. enjoy the fresh air outside";
    }
    my $new_index;
    if ($old_identifier =~ /([0-9]+$)/) {
            # if finished, loop back to beginning
            # drip forever
            $new_index = ($1 + 1) % @poems; 
    }
    # my $new_index = 0; # to create feed.xml
    my $new_identifier = $FEED_METADATA{feed_uri} . '#' . $new_index;
    my $todays_poem = $poems[$new_index];
    # $todays_poem =~ s/\n/<br>/g; # perl atom module doesn't like html5 void element <br>, i guess because that's not valid xhtml, and i don't have a way to coerce it to html
    $todays_poem =~ s/\n/<br\/>/g; # so ill use self closing <br/>
    # $todays_poem =~ s/\n/&lt;br&gt;/g;
    # $todays_poem = '<p>' . $todays_poem . '</p>';
    
    my $feed = XML::Atom::Feed->new();
    my $author = XML::Atom::Person->new();
    $author->name($FEED_METADATA{author_name});
    $feed->title($FEED_METADATA{title});
    $feed->tagline($FEED_METADATA{subtitle});
    $feed->id($FEED_METADATA{feed_uri});
    $feed->link($FEED_METADATA{link});
    $feed->author($author);
    $feed->updated($now_formatted);

    my $entry = XML::Atom::Entry->new();
    $entry->title('a poem for your day');
    $entry->id($new_identifier);
    $entry->updated($now_formatted);
    $entry->content($todays_poem); # should auto-escape any naughty characters

    # be ephemeral! the feed only holds one poem at a time
    $feed->add_entry($entry);

    # finish, I/O
    # consider print $feed->as_xml, then `script.perl > feed.xml`
    my $xml = $feed->as_xml();
    write_file($FEED_FILE, $xml);
    print STDERR "updated feed:\n";
    print STDERR $feed->as_xml();
    die;
}

generate_feed();
