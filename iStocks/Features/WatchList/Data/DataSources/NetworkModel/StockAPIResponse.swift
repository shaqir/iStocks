//
//  StockAPIResponse.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation

//Maps raw JSON from API. Kept separate from domain model.
//Decodable only, tightly coupled to server response.
struct StockAPIResponse: Decodable {
    let symbol: String
    let price: String
    let change: String
    let percent_change: String
}

// Sample JSON Response
//URL:https://api.twelvedata.com/quote?symbol=AAPL&apikey=YOUR_API_KEY
/*
{
  "symbol": "AAPL",
  "price": "189.32",
  "change": "-0.63",
  "percent_change": "-0.33%",
  "volume": "31250988"
}
*/

