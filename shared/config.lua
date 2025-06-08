--[[------------------------>FOR ASSISTANCE,SCRIPTS AND MORE JOIN OUR DISCORD<-------------------------------------
 ________   ________    ________      ___    ___      ________   _________   ___  ___   ________   ___   ________     
|\   __  \ |\   ___  \ |\   __  \    |\  \  /  /|  ||  |\   ____\ |\___   ___\|\  \|\  \ |\   ___ \ |\  \ |\   __  \    
\ \  \|\  \\ \  \\ \  \\ \  \|\  \   \ \  \/  / /  ||  \ \  \___|_\|___ \  \_|\ \  \\\  \\ \  \_|\ \\ \  \\ \  \|\  \   
 \ \   __  \\ \  \\ \  \\ \  \\\  \   \ \    / /   ||   \ \_____  \    \ \  \  \ \  \\\  \\ \  \ \\ \\ \  \\ \  \\\  \  
  \ \  \ \  \\ \  \\ \  \\ \  \\\  \   /     \/    ||    \|____|\  \    \ \  \  \ \  \\\  \\ \  \_\\ \\ \  \\ \  \\\  \ 
   \ \__\ \__\\ \__\\ \__\\ \_______\ /  /\   \    ||      ____\_\  \    \ \__\  \ \_______\\ \_______\\ \__\\ \_______\
    \|__|\|__| \|__| \|__| \|_______|/__/ /\ __\   ||     |\_________\    \|__|   \|_______| \|_______| \|__| \|_______|
                                     |__|/ \|__|   ||     \|_________|                                                 
------------------------------------->(https://discord.gg/gbJ5SyBJBv)---------------------------------------------------]]
Config = {}
Config.Debug = false -- Enable debug logs
Config.Framework = 'auto' -- 'esx', 'qb', 'qbx','auto'
Config.Language = 'en' -- 'en'
Config.Target = 'ox' -- 'ox', 'qb'
Config.BaseWaitTime = 60 -- Base wait time between orders (in seconds)
Config.RepMultiplier = 5 -- +1 rep = -5 seconds, -1 rep = +5 seconds
Config.DeliveryTime = 150 -- 2.5 minutes in seconds
Config.DeliveryTimeMinutes = 2.5 -- For display purposes
Config.FastDeliveryTime = 60 -- Time for tip bonus (in seconds)

Config.UISystem = {
    Notify = 'ox',        -- 'ox'
    TextUI = 'ox',        -- 'ox'
    ProgressBar = 'ox',   -- 'ox'
    AlertDialog = 'ox',   -- 'ox'
}
Config.JobNPC = {
    coords = vector3(-1216.78, -1504.25, 4.35),
    heading = 127.24,
    model = 'a_m_y_business_01',
    blip = {
        enabled = true,
        sprite = 280,
        color = 5,
        scale = 0.8
    }
}
Config.Reputation = {
    fastDelivery = 2,      -- Delivered within 60 seconds
    normalDelivery = 1,    -- Delivered on time
    lateDelivery = -5,     -- Delivered late
    cancelledOrder = -10   -- Cancelled order
}
Config.Rewards = {
    min = 100, -- Minimum Base amount
    max = 1000, -- Maximum Base amount
    tipMin = 50,  -- Minimum tip amount
    tipMax = 200  -- Maximum tip amount
}
Config.Restaurants = {
    {
        name = "Burgershot",
        coords = vector3(-1200.67, -885.24, 13.49),
        blip = {
            sprite = 106,
            color = 1,
            scale = 0.7
        },
        items = {
            {name = "bleeder_burger", min = 1, max = 5},
            {name = "cola", min = 1, max = 5},
            {name = "fries", min = 1, max = 3},
            {name = "water", min = 1, max = 3}
        }
    },
    {
        name = "Up-n-Atom Burger",
        coords =  vector3(90.67, 297.93, 110.21),
        blip = {
            sprite = 106,
            color = 5,
            scale = 0.7
        },
        items = {
            {name = "hamburger", min = 1, max = 4},
            {name = "cheeseburger", min = 1, max = 3},
            {name = "cola", min = 1, max = 5},
            {name = "fries", min = 1, max = 4},
            {name = "milkshake", min = 1, max = 2}
        }
    },
    {
        name = "Bean Machine Coffee",
        coords =  vector3(127.73, -1028.80, 29.45),
        blip = {
            sprite = 52,
            color = 8,
            scale = 0.7
        },
        items = {
            {name = "coffee", min = 1, max = 5},
            {name = "cappuccino", min = 1, max = 3},
            {name = "latte", min = 1, max = 3},
            {name = "donut", min = 1, max = 6},
            {name = "muffin", min = 1, max = 4},
            {name = "bagel", min = 1, max = 3}
        }
    },
    {
        name = "Tacos",
        coords =  vector3(10.89, -1606.46, 29.39),
        blip = {
            sprite = 52,
            color = 81,
            scale = 0.7
        },
        items = {
            {name = "taco", min = 2, max = 8},
            {name = "burrito", min = 1, max = 4},
            {name = "quesadilla", min = 1, max = 3},
            {name = "nachos", min = 1, max = 2},
            {name = "salsa", min = 1, max = 4},
            {name = "guacamole", min = 1, max = 2}
        }
    },
    {
        name = "Hornys Burgers",
        coords =  vector3(1234.77, -354.83, 69.08),
        blip = {
            sprite = 106,
            color = 2,
            scale = 0.7
        },
        items = {
            {name = "hornys_burger", min = 1, max = 4},
            {name = "spicy_burger", min = 1, max = 3},
            {name = "curly_fries", min = 1, max = 4},
            {name = "spicy_sauce", min = 1, max = 3},
            {name = "ice_cream", min = 1, max = 2}
        }
    }
}
Config.DeliveryPoints = {
    vector3(-1564.33, -300.34, 48.23),
    vector3(-1569.69, -295.13, 48.28),
    vector3(-1574.86, -290.26, 48.28),
    vector3(-1566.28, -280.06, 48.28),
    vector3(-1560.71, -285.25, 48.28),
    vector3(-1555.30, -289.89, 48.27),
    vector3(-1582.42, -278.20, 48.28),
    vector3(76.29, -1948.12, 21.17),
    vector3(85.89, -1959.81, 21.12),
    vector3(114.48, -1961.09, 21.33),
    vector3(126.74, -1930.07, 21.38),
    vector3(118.41, -1921.01, 21.32),
    vector3(101.08, -1912.17, 21.41),
    vector3(56.66, -1922.90, 21.91),
    vector3(1259.75, -711.17, 64.51),
    vector3(1231.63, -713.98, 60.65),
    vector3(1220.99, -689.43, 61.10),
    vector3(1204.89, -557.76, 69.62)   

}
Config.Notifications = {
    jobStarted = {
        type = 'success'
    },
    newOrder = {
        type = 'inform'
    },
    orderCancelled = {
        type = 'error'
    },
    orderComplete = {
        type = 'success'
    },
    orderLate = {
        type = 'warning'
    },
    fastDelivery = {
        type = 'success'
    }
}
Config.ProgressBars = {
    pickupOrder = {
        duration = 5000,
        animation = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    },
    deliverOrder = {
        duration = 3000,
        animation = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    }
}
Config.AntiCheat = {
    maxDistance = 10.0,
    serverValidation = true
}