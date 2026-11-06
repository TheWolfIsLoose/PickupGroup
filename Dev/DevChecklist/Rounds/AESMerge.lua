DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["AES Group Finder"] = {
    round = "restocking parity + talent builds",
    items = {
        { "restocking", "Utilities > Restocking: tick Show Only Items You're Short On; only short rows stay.", "screenshot" },
        { "restocking", "Same on the Warband List; untick brings every row back.", "yes / no" },
        { "restocking", "/aes restock debug prints on, then run one AH restock.", "log" },
        { "talent builds", "Utilities > Talent Builds: switch it on; chat says your TalentKeeper builds came in.", "yes / no" },
        { "talent builds", "Open talents: pane beside it in the AES look, your builds and tags all there.", "screenshot" },
        { "talent builds", "Click a build on the other hero tree: marks sit on the right talents.", "screenshot" },
        { "talent builds", "Apply it: lands, loadout dropdown reads Talent Builds, no BugSack errors.", "yes / no" },
        { "talent builds", "Pane's three bars open the Talent Builds tab; move the size slider: window resizes.", "yes / no" },
        { "talent builds", "/aes talents opens this spec's quick list. Then /reload.", "log" },
    },
}
