//
//  BarChartView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 19.06.2021.
//

import SwiftUI
import SwiftUICharts
import CoreData

struct BarChartView: View {
    private let data: BarChartData
    
    init(_ chartData: ChartData) {
        self.data = BarChartView.weekOfData(chartData)
    }
    
    var body: some View {
        BarChart(chartData: data)
            .touchOverlay(chartData: data)
            .averageLine(chartData: data, strokeStyle: StrokeStyle(lineWidth: 3, dash: [5,10]))
            .xAxisGrid(chartData: data).yAxisGrid(chartData: data)
            .xAxisLabels(chartData: data)
            .yAxisLabels(chartData: data, colourIndicator: .custom(colour: ColourStyle(colour: .red), size: 12))
            .headerBox(chartData: data)
            .id(data.id)
    }
    
    static func weekOfData(_ chartData: ChartData) -> BarChartData {
                
        let calendar = Calendar.current
        var dataPoints = [BarChartDataPoint]()
        
        for month in calendar.standaloneMonthSymbols {
            let randomColor = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
            let value = chartData.pointData[month] ?? 0
            dataPoints.append(BarChartDataPoint(value: value,
                                                xAxisLabel: month,
                                                description: month,
                                                colour: ColourStyle(colour: randomColor)))
        }
        
        let data: BarDataSet = BarDataSet(dataPoints: dataPoints)
        
        let gridStyle = GridStyle(numberOfLines: 5, lineColour: Color(.lightGray).opacity(0.25), lineWidth: 1)
        
        let chartStyle = BarChartStyle(infoBoxPlacement   : .header,
                                       markerType         : .bottomLeading(),
                                       xAxisGridStyle     : gridStyle,
                                       xAxisLabelPosition : .bottom,
                                       xAxisLabelsFrom    : .dataPoint(rotation: .degrees(-90)),
                                       yAxisGridStyle     : gridStyle,
                                       yAxisLabelPosition : .leading,
                                       yAxisNumberOfLabels: 5
//                                       baseline           : .zero,
//                                       topLine            : .maximumValue
        )
        
        return BarChartData(dataSets: data,
                            metadata: ChartMetadata(title: chartData.title, subtitle: chartData.subTitle ?? "",
                                                    titleFont: .system(size: 20, weight: .bold), subtitleColour: .gray),
                            barStyle: BarStyle(barWidth: 0.5,
                                               colourFrom: .dataPoints,
                                               colour: ColourStyle(colour: .blue)),
                            chartStyle: chartStyle)
    }
    
    
}


//struct BarChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        FuelBarChartView()
//    }
//}
