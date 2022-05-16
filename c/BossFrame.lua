local db, core

BossFrame = CreateFrame("Frame")

function BossFrame:init()

    core = TALC
    db = TALC_DB

    TalcBossFrame:Hide()
end

BossFrame.Bosses = {
    --Ragefire Chasm – 13-18
    'Taragaman the Hungerer', 'Oggleflint', 'Bazzalan', 'Jergosh the Invoker',

    --Wailing Caverns – 17-24
    'Kresh', 'Skum', 'Lady Anacondra', 'Lord Cobrahn', 'Lord Pythas', 'Lord Serpentis', 'Verdan the Everliving',
    'Mutanus the Devourer', 'Deviate Faerie Dragon',

    --The Deadmines – 18-23
    'Rhahk\'zor', 'Sneed', 'Gilnid', 'Edwin VanCleef', 'Cookie', 'Miner Johnson', 'Mr. Smite', 'Captain Greenskin',

    --Shadowfang Keep – 22-30
    'Razorclaw the Butcher', 'Baron Silverlaine', 'Fenrus the Devourer', 'Odo the Blindwatcher', 'Archmage Arugal', 'Deathsworn Captain',
    'Commander Springvale', 'Wolf Master Nandos', 'Rethilgore',

    --Blackfathom Deeps – 20-30
    'Lorgus Jett', 'Twilight Lord Kelris', 'Gelihast', 'Aku\'mai', 'Ghamoo-ra', 'Baron Aquanis',
    'Old Serra\'kis', 'Lady Sarevess',

    --The Stockade – 22-30
    'Targorr the Dread', 'Kam Deepfury', 'Hamhock', 'Bruegal Ironknuckle', 'Bazil Thredd', 'Dextren Ward',

    --Gnomeregan – 24-34
    'Viscous Fallout', 'Grubbis', 'Crowd Pummeler 9-60', 'Electrocutioner 6000', 'Dark Iron Ambassador', 'Mekgineer Thermaplugg',

    --Razorfen Kraul – 30-40

    'Aggem Thorncurse', 'Agathelos the Raging', 'Charlga Razorflank', 'Roogug', 'Death Speaker Jargba', 'Overlord Ramtusk',
    'Blind Hunter', 'Earthcaller Halmgar',

    --Scarlet Monastery – 26-45

    'Herod',
    'Interrogator Vishas', 'Bloodmage Thalnos', 'Azshir the Sleepless', 'Fallen Champion', 'Ironspire',
    'Houndmaster Loksey', 'Arcanist Doan',
    'High Inquisitor Fairbanks', 'Scarlet Commander Mograine', 'High Inquisitor Whitemane',

    --Razorfen Downs – 40-50
    'Mordresh Fire Eye', 'Ragglesnout', 'Tuten\'kash', 'Glutton', 'Amnennar the Coldbringer', 'Plaguemaw the Rotting',

    --Uldaman – 35-45

    'Revelosh', 'Ironaya', 'Obsidian Sentinel', 'Ancient Stone Keeper',
    'Grimlok', 'Archaedas', 'Galgann Firehammer', 'Baelog', 'Olaf', 'Eric "The Swift"',

    --Zul’Farrak – 42-46
    'Theka the Martyr', 'Antu\'sul', 'Witch Doctor Zum\'rah', 'Sandfury Executioner',
    'Sergeant Bly', 'Ruuzlu', 'Hydromancer Velratha', 'Zerillis',
    'Nekrum Gutchewer', 'Shadowpriest Sezz\'ziz', 'Dustwraith',
    'Gahz\'rilla', 'Chief Ukorz Sandscalp',

    --Maraudon – 46-55
    'Tinkerer Gizlock', 'Lord Vyletongue',
    'Noxxion', 'Razorlash',
    'Landslide', 'Rotgrip', 'Princess Theradras',
    'Celebras the Cursed', 'Meshlok the Harvester',

    --Temple of Atal’Hakkar – 55-60
    'Hazzas', 'Morphaz', 'Jammal\'an the Prophet',
    'Shade of Eranikus', 'Atal\'alarion',
    'Ogom the Wretched', 'Weaver',
    'Morphaz', 'Dreamscythe', 'Avatar of Hakkar', 'Spawn of Hakkar',

    --Blackrock Depths – 52-60
    'High Interrogator Gerstahn', 'Houndmaster Grebmar', 'Lord Roccor', 'Golem Lord Argelmach', 'Hurley Blackbreath',
    'Bael\'Gar', 'General Angerforge', 'Plugger Spazzring', 'Ribbly Screwspigot',
    'Fineous Darkvire', 'Emperor Dagran Thaurissan', 'Panzor the Invincible',
    'Phalanx', 'Lord Incendius', 'Warder Stilgiss', 'Verek', 'Watchman Doomgrip',
    'Pyromancer Loregrain', 'Ambassador Flamelash', 'Magmus', 'Princess Moira Bronzebeard',
    'Gorosh the Dervish', 'Grizzle', 'Eviscerator', 'Ok\'thor the Breaker', 'Anub\'shiah', 'Hedrum the Creeper',

    --Lower Blackrock Spire – 55-60
    'Mother Smolderweb', 'Bannok Grimaxe', 'Crystal Fang', 'Ghok Bashguud', 'Spirestone Butcher',
    'Overlord Wyrmthalak', 'Burning Felguard', 'Spirestone Battle Lord', 'Spirestone Lord Magus',
    'Highlord Omokk', 'Urok Doomhowl', 'Quartermaster Zigris', 'Halycon', 'Gizrul the Slavener', 'War Master Voone',

    --Upper Blackrock Spire – 55-60
    'Jed Runewatcher', 'Gyth', 'Warchief Rend Blackhand',
    'Pyroguard Emberseer', 'Solakar Flamewreath', 'Goraluk Anvilcrack',
    'The Beast', 'General Drakkisath',
    'Lord Valthalak',

    --Dire Maul – 55-60

    'Guard Mol\'dar', 'Stomper Kreeg', 'Guard Fengus', 'Guard Slip\'kik', 'Captain Kromcrush', 'Cho\'Rush the Observer', 'King Gordok',
    'Pusilin', 'Zevrim Thornhoof', 'Hydrospawn', 'Lethtendris', 'Alzzin the Wildshaper',
    'Tendris Warpwood', 'Illyanna Ravenoak', 'Magister Kalendris', 'Immol\'thar', 'Prince Tortheldrin',
    'Tsu\'zee', 'Lord Hel\'nurath',

    --Scholomance – 58 - 60
    'Marduk Blackpool', 'Doctor Theolen Krastinov', 'Lorekeeper Polkelt', 'The Ravenian', 'Darkmaster Gandling',
    'Kirtonos the Herald', 'Blood Steward of Kirtonos', 'Jandice Barov', 'Rattlegore', 'Death Knight Darkreaver',
    'Instructor Malicia', 'Vectus', 'Ras Frostwhisper', 'Lady Illucia Barov', 'Lord Alexei Barov',

    --Stratholme – 58 - 60
    'Stratholme Courier', 'The Unforgiven', 'Cannon Master Wiley', 'Grand Crusader Dathrohan', 'Timmy the Cruel',
    'Archivist Galford', 'Malor the Zealous', 'Hearthsinger Forresten', 'Skul', 'Postmaster Malown',
    'Magistrate Barthilas', 'Ramstein the Gorger', 'Nerub\'enkan', 'Maleki the Pallid', 'Baroness Anastari', 'Baron Rivendare', 'Stonespire',


    --    Zul'Gurub
    'High Priestess Jeklik', 'High Priest Venoxis', 'High Priestess Mar\'li', 'High Priest Thekal',
    'High Priestess Arlokk', 'Bloodlord Mandokir', 'Jin\'do the Hexxer', 'Gahz\'ranka', 'Gri\'lek',
    'Hazza\'rah', 'Renataki', 'Wushoolay', 'Hakkar the Soulflayer',

    --Ruins of Ahn'Qiraj
    'Kurinnaxx', 'General Rajaxx', 'Moam', 'Buru the Gorger', 'Ayamiss the Hunter', 'Ossirian the Unscarred',

    --Molten Core
    'Lucifron', 'Magmadar', 'Gehennas', 'Garr', 'Baron Geddon', 'Shazzrah', 'Golemagg the Incinerator',
    'Sulfuron Harbinger', 'Majordomo Executus', 'Ragnaros',

    --Blackwing Lair
    'Razorgore the Untamed', 'Vaelastrasz the Corrupt', 'Broodlord Lashlayer', 'Flamegor', 'Ebonroc',
    'Firemaw', 'Chromaggus', 'Nefarian',

    --Onyxia's Lair
    'Onyxia',

    --The Temple of Ahn'Qiraj
    'The Prophet Skeram', 'Lord Kri', 'Princess Yauj', 'Vem', 'Battleguard Sartura', 'Fankriss the Unyielding',
    'Viscidus', 'Princess Huhuran', 'Emperor Vek\'lor', 'Emperor Vek\'nilash', 'Ouro', 'C\'Thun',

    --Naxxramas
    'Anub\'Rekhan', 'Grand Widow Faerlina', 'Maexxna',
    'Noth the Plaguebringer', 'Heigan the Unclean', 'Loatheb',
    'Instructor Razuvious', 'Gothik the Harvester',
    'Highlord Mograine', 'Thane Korth\'azz', 'Lady Blaumeux', 'Sir Zeliek',
    'Patchwerk', 'Grobbulus', 'Gluth', 'Thaddius',
    'Sapphiron', 'Kel\'Thuzad',

    --WORLD BOSSES
    'Azuregos', 'Lord Kazzak', 'Teremus the Devourer',
    'Emeriss', 'Lethon', 'Taerar', 'Ysondre',
    'Nerubian Overseer',
    'Turtlhu, the Black Turtle of Doom',
    'Snowball', 'Dark Reaver of Karazhan'
};

BossFrame.animation = CreateFrame("Frame")
BossFrame.animation:Hide()

BossFrame.animation:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

BossFrame.animation.frameIndex = 0
BossFrame.animation.doAnim = false
BossFrame.animation.active = false

BossFrame.animation:SetScript("OnUpdate", function()

    if BossFrame.animation.active then

        if ((GetTime()) >= (this.startTime) + 0.03) then

            this.startTime = GetTime()

            local image = 'bossbanner_';

            if BossFrame.animation.frameIndex < 10 then
                image = image .. '0' .. BossFrame.animation.frameIndex
            else
                image = image .. BossFrame.animation.frameIndex;
            end

            BossFrame.animation.frameIndex = BossFrame.animation.frameIndex + 1

            if BossFrame.animation.doAnim then
                if BossFrame.animation.frameIndex <= 30 then
                    TalcBossFrameBackground:SetTexture('Interface\\AddOns\\Talc\\images\\boss\\' .. image)
                end
            end

            if BossFrame.animation.frameIndex == 29 then
                --stop and hold last frame
                BossFrame.animation.doAnim = false
            end

            if BossFrame.animation.frameIndex > 12 then
                if TalcBossFrameBossName:GetAlpha() < 0.9 then
                    TalcBossFrameBossName:SetAlpha(TalcBossFrameBossName:GetAlpha() + 0.16)
                    TalcBossFrameHasBeenDefeated:SetAlpha(TalcBossFrameHasBeenDefeated:GetAlpha() + 0.16)
                end
            end

            if BossFrame.animation.frameIndex > 119 then
                TalcBossFrameBackground:SetAlpha(frame:GetAlpha() - 0.03)
                TalcBossFrameBossName:SetAlpha(frame:GetAlpha())
                TalcBossFrameHasBeenDefeated:SetAlpha(frame:GetAlpha())
            end

            if BossFrame.animation.frameIndex >= 150 then

                BossFrame.animation:Hide()
                BossFrame.animation.frameIndex = 0
                BossFrame.animation.active = false

                TalcBossFrameBossName:SetAlpha(0)
                TalcBossFrameHasBeenDefeated:SetAlpha(0)

                TalcBossFrame:Hide()
                TalcBossFrameBackground:Hide()
            end
        end
    end
end)

function BossFrame:StartBossAnimation(boss)

    if not TalcBossFrame:IsVisible() then

        TalcBossFrameBossName:SetText(boss)
        TalcBossFrameBossName:SetAlpha(0);

        TalcBossFrameHasBeenDefeated:SetAlpha(0);

        BossFrame.animation.frameIndex = 0
        BossFrame.animation.doAnim = true
        BossFrame.animation.active = true

        TalcBossFrameBackground:SetTexture('Interface\\AddOns\\Talc\\images\\boss\\bossbanner_01')
        TalcBossFrameBackground:Show()
        TalcBossFrameBackground:SetAlpha(1)

        TalcBossFrame:Show();

        BossFrame.animation:Show()
    end
end
