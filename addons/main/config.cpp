#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = QUOTE(COMPONENT);
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"cba_main"};
        author = "Seb";
        VERSION_CONFIG;
    };
};

class CfgFunctions {
    class HT {
        class Helicopter_Turbulence {
            file = "z\HT\addons\main\functions";
            class turbulence {};
            class turbLogic {};
        };
    };
};

#include "CfgEventHandlers.hpp"
