//
//  LineChartView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 05.07.2021.
//

import SwiftUI
import SwiftUICharts
import CoreData

struct LineChartView: View {
    private let data: LineChartData
    private let roundBy: Int
        
    init(_ chartData: ChartData, roundBy: Int = 0) {
        self.data = LineChartView.weekOfData(chartData)
        self.roundBy = roundBy
    }
    
    var body: some View {
        LineChart(chartData: data)
            .touchOverlay(chartData: data, specifier: "%.\(roundBy)f")
            .averageLine(chartData: data, markerName: "Average", strokeStyle: StrokeStyle(lineWidth: 3, dash: [5,10]))
            .xAxisGrid(chartData: data).yAxisGrid(chartData: data)
            .xAxisLabels(chartData: data)
            .yAxisLabels(chartData: data, colourIndicator: .style(size: 12))
            .infoBox(chartData: data).headerBox(chartData: data)
            .id(data.id)
            .padding(.horizontal)
    }
    
        
    static func weekOfData(_ chartData: ChartData) -> LineChartData {
        let calendar = Calendar.current
        var dataPoints = [LineChartDataPoint]()
        
        for month in calendar.standaloneMonthSymbols {
            let value = chartData.pointData[month] ?? 0
            dataPoints.append(LineChartDataPoint(value: value, xAxisLabel: month, description: month))
        }

        let randomColor = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))

        let data = LineDataSet(dataPoints: dataPoints,
                               style: LineStyle(lineColour: ColourStyle(colour: randomColor), lineType: .curvedLine))
        

        let gridStyle  = GridStyle(numberOfLines: dataPoints.count,
                                   lineColour: Color(.lightGray).opacity(0.25), lineWidth: 1)
        
        let chartStyle = LineChartStyle(infoBoxPlacement: .infoBox(isStatic: false), infoBoxContentAlignment: .vertical,
                                        infoBoxBorderColour: Color.primary,
                                        infoBoxBorderStyle: StrokeStyle(lineWidth: 1), xAxisGridStyle: gridStyle,
                                        xAxisLabelPosition: .bottom, xAxisLabelColour: Color.primary,
                                        xAxisLabelsFrom: .dataPoint(rotation: .degrees(-90)), yAxisGridStyle: gridStyle,
                                        yAxisLabelPosition: .leading, yAxisLabelColour: Color.primary,
                                        yAxisNumberOfLabels: 5, globalAnimation: .easeOut(duration: 1))
        
        return LineChartData(dataSets: data,
                             metadata: ChartMetadata(title: chartData.title, subtitle: chartData.subTitle ?? "",
                                                     titleFont: .system(size: 20, weight: .bold),
                                                     subtitleColour: .gray),
                             chartStyle: chartStyle)
        
    }
}

//struct LineChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        LineChartView()
//    }
//}
