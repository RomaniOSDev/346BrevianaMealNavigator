import SwiftUI

struct ChartBar: Identifiable {
    let id: String
    let label: String
    let value: Double
    let color: Color
}

struct KitchenBarChart: View {
    let bars: [ChartBar]
    var unitLabel: String = ""

    private var maxValue: Double {
        max(bars.map(\.value).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(bars) { bar in
                    VStack(spacing: 6) {
                        Text(valueText(bar.value))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Palette.ink)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [bar.color, bar.color.opacity(0.72)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: barHeight(bar.value))
                        Text(bar.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Palette.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 168, alignment: .bottom)

            if unitLabel.isEmpty == false {
                Text(unitLabel)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Palette.muted)
            }
        }
    }

    private func barHeight(_ value: Double) -> CGFloat {
        let ratio = value / maxValue
        return max(8, CGFloat(ratio) * 132)
    }

    private func valueText(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

struct KitchenHBarChart: View {
    let bars: [ChartBar]

    private var maxValue: Double {
        max(bars.map(\.value).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(bars) { bar in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bar.label)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Palette.ink)
                        Spacer()
                        Text(bar.value == bar.value.rounded() ? "\(Int(bar.value))" : String(format: "%.0f", bar.value))
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.muted)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Palette.fieldFill)
                            Capsule()
                                .fill(bar.color)
                                .frame(width: max(8, geo.size.width * CGFloat(bar.value / maxValue)))
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
    }
}

struct KitchenDonutChart: View {
    let slices: [ChartBar]

    private var total: Double {
        max(slices.reduce(0) { $0 + $1.value }, 1)
    }

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Palette.fieldFill, lineWidth: 22)
                ForEach(Array(sliceRanges().enumerated()), id: \.offset) { _, item in
                    Circle()
                        .trim(from: item.start, to: item.end)
                        .stroke(item.bar.color, style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 2) {
                    Text("\(Int(slices.reduce(0) { $0 + $1.value }))")
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .foregroundColor(Palette.ink)
                    Text("total")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(Palette.muted)
                }
            }
            .frame(width: 132, height: 132)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(slices) { slice in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                        Text(slice.label)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(Palette.ink)
                        Spacer(minLength: 0)
                        Text("\(Int(slice.value))")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.muted)
                    }
                }
            }
        }
    }

    private struct SliceRange {
        let bar: ChartBar
        let start: CGFloat
        let end: CGFloat
    }

    private func sliceRanges() -> [SliceRange] {
        var cursor: CGFloat = 0
        return slices.map { slice in
            let share = CGFloat(slice.value / total)
            let start = cursor
            cursor += share
            return SliceRange(bar: slice, start: start, end: cursor)
        }
    }
}
