-- StockClerk's test round. Only rewritten while working on StockClerk; emptied once all ticked.
DevChecklist_Rounds = DevChecklist_Rounds or {}
DevChecklist_Rounds["StockClerk"] = {
    round = "suite style pass",
    items = {
        { "chat", "/clerk: load line and help say StockClerk in white + gray; /clerk in white. No mint anywhere.", "say yes / no" },
        { "window", "Open StockClerk (Mine): white icon before the title, Stock white / Clerk gray, version 'dev 22bf347' in yellow. Column headings, the lit tab and the funnel are white; items you have enough of show Have in white, short ones red; caps white (red when over).", "screenshot" },
        { "window", "Switch to Warband: headings, lit tab and accents turn blue; switch back to Mine: white again.", "say yes / no" },
        { "window", "Buttons (Restock, bulk import's Add, the log's Clear, the sidecar's add) are 20px with the small font; header icons light gray at rest, white on hover.", "screenshot" },
        { "sidecar", "Settings & Activity: Settings and Recent activity titles white, checkbox squares white, errors in the feed red.", "screenshot" },
        { "auction house", "Next AH restock: checkout marks (chevron, check) are white in Mine, warnings yellow, Done white. Then /reload so I can read the log.", "screenshot of the checkout or receipt" },
    },
}
