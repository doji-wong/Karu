import SwiftUI
import KaruCore

/// 3D Pop-Out Orbiting Flight Ticket.
/// Pure cutout ticket shape with transparent background, continuous animated orbiting jet trail,
/// tactile scissor tear-off, and post-tear cabin seat selection.
public struct OrbitingTicketPopoutView: View {
    public var originAirport: DestinationAirport
    public var destinationAirport: DestinationAirport
    public var durationMinutes: Int
    public var onSelectSeatAndTakeoff: (FocusSeatClass) -> Void
    public var onClose: () -> Void
    
    // Interactive State
    @State private var selectedSeat: FocusSeatClass = .code // Default Seat 07F (Coding & Ship)
    @State private var tearProgress: CGFloat = 0.0 // 0.0 to 1.0
    @State private var isTicketTorn: Bool = false
    @State private var isSeatSelectionActive: Bool = false
    @State private var stubOffset: CGFloat = 0.0
    @State private var stubRotation: Double = 0.0
    
    public init(
        originAirport: DestinationAirport,
        destinationAirport: DestinationAirport,
        durationMinutes: Int,
        onSelectSeatAndTakeoff: @escaping (FocusSeatClass) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.originAirport = originAirport
        self.destinationAirport = destinationAirport
        self.durationMinutes = durationMinutes
        self.onSelectSeatAndTakeoff = onSelectSeatAndTakeoff
        self.onClose = onClose
    }
    
    private var formattedDateString: String {
        return KaruFormatters.formatTicketDate()
    }
    
    private var calculatedDistanceFormatted: String {
        let km = originAirport.distanceKm(to: destinationAirport)
        return KaruFormatters.formatDistanceKm(km)
    }
    
    private var seatCodeFormatted: String {
        switch selectedSeat {
        case .deepWork: return "01A"
        case .study: return "02B"
        case .research: return "03C"
        case .read: return "04D"
        case .code: return "07F"
        }
    }
    
    public var body: some View {
        // ── Pure Cutout Ticket Card (Zero outer background container) ──
        VStack(spacing: 0) {
            // Top Header with Integrated Dismiss Button
            HStack {
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: 0x38BDF8)).frame(width: 6, height: 6)
                    Text("FOCUS FLIGHT DECK")
                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                        .tracking(1.0)
                }
                
                Spacer()
                
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: 0x64748B))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)
            
            // ── 1. Upper Ticket Body with Dotted World Map ──
            ZStack(alignment: .top) {
                DottedWorldMapView()
                    .opacity(0.4)
                    .frame(maxWidth: CGFloat.infinity, maxHeight: 175)
                    .clipped()
                
                VStack(spacing: 12) {
                    // Route Header: VKO ➔ MEX
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(originAirport.code)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white)
                            Text(originAirport.cityName)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Color(hex: 0x94A3B8))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Image(systemName: "airplane")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: 0x38BDF8))
                            
                            Text("\(durationMinutes)m 00s")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: 0xE2E8F0))
                        }
                        .padding(.top, 3)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(destinationAirport.code)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white)
                            Text(destinationAirport.cityName)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Color(hex: 0x94A3B8))
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // 2x2 Telemetry Grid (Seat, Distance, Boarding, Date)
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Seat")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x94A3B8))
                                HStack(spacing: 4) {
                                    Text(seatCodeFormatted)
                                        .font(.system(size: 15, weight: .black, design: .monospaced))
                                        .foregroundStyle(Color.white)
                                    Text("· \(selectedSeat.title)")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x38BDF8))
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Distance")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x94A3B8))
                                Text(calculatedDistanceFormatted)
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Boarding")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x94A3B8))
                                Text(isTicketTorn ? "Boarded" : "Now")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundStyle(isTicketTorn ? Color(hex: 0x4ADE80) : Color.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Date")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x94A3B8))
                                Text(formattedDateString)
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.white)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(14)
            }
            .background(Color(hex: 0x18181B))
            
            // ── 2. Perforated Notch Tear Divider ──
            HStack(spacing: 0) {
                TicketPerforationLine()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color(hex: 0x3F3F46))
                    .frame(height: 1)
            }
            .padding(.horizontal, 14)
            .frame(height: 12)
            .background(Color(hex: 0x18181B))
            
            // ── 3. Bottom Section: Barcode Stub or Seat Selection ──
            if !isSeatSelectionActive {
                VStack(spacing: 10) {
                    // Scissor Drag Perforation Handle
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: 0x27272A))
                            .frame(height: 36)
                        
                        Text("DRAG SCISSOR TO TEAR TICKET")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x64748B))
                            .frame(maxWidth: .infinity)
                        
                        GeometryReader { geo in
                            let w = geo.size.width
                            let handleX = tearProgress * (w - 36)
                            
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0x38BDF8), Color(hex: 0x0284C7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color(hex: 0x0284C7).opacity(0.6), radius: 6, x: 0, y: 2)
                                
                                Image(systemName: "scissors")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(Color.white)
                                    .rotationEffect(.degrees(isTicketTorn ? 45 : 0))
                            }
                            .offset(x: handleX)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newProgress = min(1.0, max(0.0, value.location.x / w))
                                        tearProgress = newProgress
                                        if newProgress >= 0.95 && !isTicketTorn {
                                            performTicketTear()
                                        }
                                    }
                                    .onEnded { _ in
                                        if tearProgress < 0.95 {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                tearProgress = 0.0
                                            }
                                        }
                                    }
                            )
                        }
                        .frame(height: 36)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    
                    // Curved 2D Barcode Bottom Stub
                    CurvedBarcodeView()
                        .frame(height: 44)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .offset(y: stubOffset)
                        .rotationEffect(.degrees(stubRotation))
                        .opacity(isTicketTorn ? 0.0 : 1.0)
                        .padding(.horizontal, 14)
                }
                .padding(.bottom, 14)
                .background(Color(hex: 0x18181B))
            } else {
                // Post-Tear Seat Selection Grid
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("CHOOSE YOUR CABIN SEAT")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x38BDF8))
                        Spacer()
                        Text("Step 2/2")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x64748B))
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    
                    VStack(spacing: 5) {
                        ForEach(FocusSeatClass.allCases) { seat in
                            Button {
                                selectedSeat = seat
                                completeBoardingAndTakeoff()
                            } label: {
                                HStack(spacing: 9) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: UInt(seat.themeColorHex.dropFirst().description, radix: 16) ?? 0x38BDF8).opacity(0.25))
                                            .frame(width: 26, height: 26)
                                        Image(systemName: seat.iconSymbol)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Color(hex: UInt(seat.themeColorHex.dropFirst().description, radix: 16) ?? 0x38BDF8))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        HStack {
                                            Text(seat.title)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(Color.white)
                                            Text("[\(seat.seatCode)]")
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundStyle(Color(hex: 0x38BDF8))
                                        }
                                        Text(seat.subtitle)
                                            .font(.system(size: 8.5))
                                            .foregroundStyle(Color(hex: 0x94A3B8))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x64748B))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedSeat == seat ? Color(hex: 0x27272A) : Color(hex: 0x121214))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedSeat == seat ? Color(hex: 0x38BDF8).opacity(0.6) : Color(hex: 0x27272A), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                }
                .background(Color(hex: 0x18181B))
            }
        }
        .frame(width: 300)
        .background(Color(hex: 0x18181B))
        .clipShape(TicketShape(cornerRadius: 22, notchRadius: 9, notchYRatio: 0.62))
        .overlay(
            TicketShape(cornerRadius: 22, notchRadius: 9, notchYRatio: 0.62)
                .stroke(Color(hex: 0x27272A), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.9), radius: 24, x: 0, y: 12)
    }
    
    private func performTicketTear() {
        isTicketTorn = true
        withAnimation(.easeOut(duration: 0.45)) {
            stubOffset = 50
            stubRotation = -8.0
        }
        
        // Transition to seat selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isSeatSelectionActive = true
            }
        }
    }
    
    private func completeBoardingAndTakeoff() {
        onSelectSeatAndTakeoff(selectedSeat)
    }
}
