//
//  JavaScriptBridge.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import WebKit

/// Defines JavaScript bridge constants, message types, and injectable user scripts
/// for communication between WKWebView content and the native app layer.
enum JavaScriptBridge {

    // MARK: - Handler Name

    /// The message handler name registered on `window.webkit.messageHandlers`
    static let handlerName = "iStocksHandler"

    // MARK: - Message Types

    /// Inbound message types received from injected JavaScript
    enum MessageType: String {
        case tickerTapped
        case pageLoaded
        case error
    }

    // MARK: - User Scripts

    /// Scans the page for stock ticker patterns (e.g. $AAPL) and wraps them in
    /// tappable spans that post a message back to the native layer.
    static var extractTickerScript: WKUserScript {
        let source = """
        (function() {
            function highlightTickers() {
                var walker = document.createTreeWalker(
                    document.body,
                    NodeFilter.SHOW_TEXT,
                    null,
                    false
                );

                var textNodes = [];
                while (walker.nextNode()) {
                    textNodes.push(walker.currentNode);
                }

                var tickerRegex = /\\$([A-Z]{1,5})\\b/g;

                textNodes.forEach(function(node) {
                    if (!node.nodeValue.match(tickerRegex)) return;
                    if (node.parentElement && node.parentElement.classList.contains('istocks-ticker')) return;

                    var parts = node.nodeValue.split(tickerRegex);
                    if (parts.length <= 1) return;

                    var fragment = document.createDocumentFragment();
                    var matches = node.nodeValue.match(tickerRegex);
                    var matchIndex = 0;

                    for (var i = 0; i < parts.length; i++) {
                        if (i % 2 === 0) {
                            if (parts[i]) fragment.appendChild(document.createTextNode(parts[i]));
                        } else {
                            var tickerSpan = document.createElement('span');
                            tickerSpan.className = 'istocks-ticker';
                            tickerSpan.style.cssText = 'color:#007AFF;font-weight:600;cursor:pointer;text-decoration:underline;';
                            tickerSpan.dataset.symbol = parts[i];
                            tickerSpan.textContent = matches[matchIndex] || ('$' + parts[i]);
                            matchIndex++;
                            fragment.appendChild(tickerSpan);
                        }
                    }
                    node.parentNode.replaceChild(fragment, node);
                });

                document.querySelectorAll('.istocks-ticker').forEach(function(el) {
                    if (el.dataset.bound) return;
                    el.dataset.bound = 'true';
                    el.addEventListener('click', function() {
                        var symbol = el.dataset.symbol;
                        window.webkit.messageHandlers.\(handlerName).postMessage({
                            type: '\(MessageType.tickerTapped.rawValue)',
                            symbol: symbol
                        });
                    });
                });
            }

            if (document.readyState === 'complete' || document.readyState === 'interactive') {
                highlightTickers();
            }
            document.addEventListener('DOMContentLoaded', highlightTickers);

            window.webkit.messageHandlers.\(handlerName).postMessage({
                type: '\(MessageType.pageLoaded.rawValue)',
                url: window.location.href,
                title: document.title
            });
        })();
        """
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    /// Injects lightweight CSS overrides to improve readability on financial pages
    static var customStyleScript: WKUserScript {
        let source = """
        (function() {
            var style = document.createElement('style');
            style.textContent = `
                .istocks-ticker {
                    background-color: rgba(0, 122, 255, 0.08);
                    border-radius: 3px;
                    padding: 1px 4px;
                    transition: background-color 0.2s;
                }
                .istocks-ticker:active {
                    background-color: rgba(0, 122, 255, 0.25);
                }
            `;
            document.head.appendChild(style);
        })();
        """
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
}
