//
//  StatisticsView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI
import CoreData
import SwiftUICharts // https://github.com/willdale/SwiftUICharts

enum StatisticType: String, CaseIterable {
    case monthly = "Monthly"
    case total = "Total"
}


struct StatisticView: View {
    @Environment(\.managedObjectContext) var context
    var viewName: LocalizedStringKey
    @State private var statType: StatisticType = .monthly
    @State private var selection = Date()
    @State private var statYear = getNowYear()
    
    private let currSumbol = UserDef().getCurrencySumbol()
    
    var body: some View {
        NavigationView {
            if UserData(self.context).getAllExpences().count == 0 {
                Text("No Data").font(.title).bold().navigationTitle(self.viewName)
            } else {
                GeometryReader { geometry in
                    VStack {
                        Picker(selection: self.$statType, label: EmptyView()) {
                            ForEach(StatisticType.allCases, id: \.self) { statisticType in
                                Text(statisticType.rawValue.localize)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                        
                        HStack {
                            let backwardDisable = UserData(self.context).getPrices(statYear-1).sumIsZero
                            let forwardDisable = UserData(self.context).getPrices(statYear+1).sumIsZero
                            
                            Image(systemName: "arrow.backward.square")
                                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                                .foregroundColor(backwardDisable ? .gray : .blue)
                                .onTapGesture {
                                    if !backwardDisable {
                                        self.statYear -= 1
                                    }
                                }
                            Text(String(self.statYear)+" \("year".localize)")
                                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).bold()
                                .foregroundColor(dateColor)
                                .padding(.horizontal)
                            Image(systemName: "arrow.forward.square")
                                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                                .foregroundColor(forwardDisable ? .gray : .blue)
                                .onTapGesture { if !forwardDisable { self.statYear += 1 } }
                        }
                        
                        switch self.statType {
                        case .monthly:
                            ScrollView {
                                let width = geometry.size.width
                                if UserData(self.context).getPrices() != 0 {
                                    TabView {
                                        barChart(statYear, .fuel, width, width, self.context)
                                        barChart(statYear, .service, width, width, self.context)
                                        barChart(statYear, .other, width, width, self.context)
                                    }
                                    .tabViewStyle(PageTabViewStyle())
                                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                                    .frame(width: width, height: width + 50)
                                }
                                Divider()
                                TabView {
                                    lineChart(ChartComparer(statYear, self.context).distanceLineChart(), width, width)
                                    lineChart(ChartComparer(statYear, self.context).consumption(), width, width)
                                }
                                .tabViewStyle(PageTabViewStyle())
                                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                                .frame(width: width, height: width + 50)
                                
                                Divider()
                                LineChartView(ChartComparer(statYear, self.context).costPerKm(), roundBy: 2)
                                    .frame(height: width + 50).padding().padding(.leading, -15)
                            }
                            
                        case .total:
                            let cardWidth = geometry.size.width/3.4
                            VStack {
                                VStack {
                                    HStack {
                                        let distValue = UserData(self.context).getDistance(self.statYear)
                                        let distValueStr =
                                            (distValue.sum == 0 ? "" : "\(distValue.sum.toRoundedStr(0)) " + "km".localize)
                                        statCard(caption: "Distance", value: distValueStr, width: cardWidth)
                                        
                                        let expValue = UserData(self.context).getPrices(self.statYear).sum
                                        let expValueStr = (expValue == 0 ? "" : "\(expValue.toRoundedStr(0)) \(self.currSumbol)")
                                        statCard(caption: "Expenses", value: expValueStr, width: cardWidth)
                                        
                                        let consValue = UserData(self.context).getConsumption(self.statYear)
                                        let consValueStr = (consValue == 0 ? "" : consValue.toRoundedStr(1)+"l/100km".localize)
                                        statCard(caption: "Consumption", value: consValueStr, width: cardWidth)
                                    }
                                    HStack {
                                        
                                    }
                                }
                                Divider()
                                Text("All period").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).bold().foregroundColor(Color(.systemPurple))
                                HStack {
                                    let distValue = UserData(self.context).getDistance()
                                    let distValueStr = (distValue == 0 ? "" : "\(distValue) " + "km".localize)
                                    statCard(caption: "Distance", value: distValueStr, width: cardWidth)
                                    
                                    let expValue = UserData(self.context).getPrices()
                                    let expValueStr = (expValue == 0 ? "" : "\(expValue.toRoundedStr(0)) \(self.currSumbol)")
                                    statCard(caption: "Expenses", value: expValueStr, width: cardWidth)
                                    
                                    let consValue = UserData(self.context).getConsumption()
                                    let consValueStr = (consValue == 0 ? "" : consValue.toRoundedStr(1)+"l/100km".localize)
                                    statCard(caption: "Consumption", value: consValueStr, width: cardWidth)
                                }
                                
                            }.padding(.horizontal)
                        }
                        Spacer()
                    }.navigationTitle(self.viewName)
                }
            }
        }
    }
    
    
    struct barChart: View {
        let year: Int
        let expType: ExpensesType
        let width, height: CGFloat
        let context: NSManagedObjectContext
        
        init(_ year: Int, _ expType: ExpensesType, _ width: CGFloat, _ height: CGFloat, _ context: NSManagedObjectContext) {
            self.year = year
            self.expType = expType
            self.width = width
            self.height = height
            self.context = context
        }
        
        var body: some View {
            if !UserData(self.context).getPrices(self.year, expType: self.expType).sumIsZero {
                VStack {
                    let chartData = ChartComparer(self.year, self.context).pricesBarChart(self.expType)
                    BarChartView(chartData).padding(.horizontal).frame(width: self.width, height: self.height)
                    Spacer()
                }
            }
        }
    }
    
    struct lineChart: View {
        let data: ChartData
        let width, height: CGFloat

        
        init(_ chartData: ChartData, _ width: CGFloat, _ height: CGFloat) {
            self.data = chartData
            self.width = width
            self.height = height
        }
        
        var body: some View {
            VStack {
                LineChartView(self.data).padding(.horizontal).frame(width: self.width, height: self.height)
                Spacer()
            }
        }
    }
    
    
    struct statCard: View {
        let caption: LocalizedStringKey
        let value: String
        let width: CGFloat
        var body: some View {
            VStack {
                Text(caption).bold().font(.title2)
                if value != "" {
                    Text(value).font(.title3)
                } else {
                    Text("No Data".localize).font(.title3).italic()
                }
            }
            .padding(.vertical)
            .frame(width: width)
            .background(Color(.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.label), lineWidth: 1.5))
        }
    }
    
    
    static private func getNowYear() -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let year: String = dateFormatter.string(from: Date())
        return Int(year) ?? 0
    }
    
}


struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatisticView(viewName: "Statistic")
        }
    }
}
