//
//  Double.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/08/2025.
//
import SwiftUI


extension Double {
    
    /// Converts a Double into a Currency with 2-6 decimal places
        /// ```
        /// Convert 1234.56 to $1,234.56
        /// Convert 12.3456 to $12.3456
        /// Convert 0.123456 to $0.123456
        /// ```
        private var currencyFormatter6: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.usesGroupingSeparator = true // <-- gives commas btw digits
            formatter.numberStyle = .currency
            //formatter.locale = .current // <- default value
            formatter.currencyCode = "usd" // <- change currency
            formatter.currencySymbol = "$" // <- change currency symbol
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 6
            return formatter
        }
    
    
    /// Converts a Double into a Currency as a String with 2-6 decimal places
      /// ```
      /// Convert 1234.56 to "$1,234.56"
      /// Convert 12.3456 to "$12.3456"
      /// Convert 0.123456 to "$0.123456"
      /// ```
    
    // 'self' refers to the Double value calling this method, like 1234.56.asCurrencyWith6Decimals()
      func asCurrencyWith6Decimals() -> String {
          let number = NSNumber(value: self)
          return currencyFormatter6.string(from: number) ?? "$0.00"
      }
    
    /// Converts a Double into string representation
        /// ```
        /// Convert 1.2345 to "1.23"
        /// ```
        func asNumberString() -> String {
            return String(format: "%.2f", self)
        }
    
    func asPercentString() -> String {
        return asNumberString() + "%"
    }
    
    
    /// Converts a Double into a Currency with 2 decimal places
       /// ```
       /// Convert 1234.56 to $1,234.56
       /// ```
       private var currencyFormatter2: NumberFormatter {
           let formatter = NumberFormatter()
           formatter.usesGroupingSeparator = true
           formatter.numberStyle = .currency
           //formatter.locale = .current // <- default value
           //formatter.currencyCode = "usd" // <- change currency
           //formatter.currencySymbol = "$" // <- change currency symbol
           formatter.minimumFractionDigits = 2
           formatter.maximumFractionDigits = 2
           return formatter
       }
       
       /// Converts a Double into a Currency as a String with 2 decimal places
       /// ```
       /// Convert 1234.56 to "$1,234.56"
       /// ```
       func asCurrencyWith2Decimals() -> String {
           let number = NSNumber(value: self)
           return currencyFormatter2.string(from: number) ?? "$0.00"
       }
}

