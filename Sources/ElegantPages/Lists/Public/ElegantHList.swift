// Kevin Li - 6:13 PM - 6/23/20

import SwiftUI

public struct ElegantHList: View, ElegantListManagerDirectAccess {

    @ObservedObject public var manager: ElegantListManager
    public let pageTurnType: PageTurnType
    public let bounces: Bool
    public let viewForPage: (Int) -> AnyView

    private var pagerWidth: CGFloat {
        screen.width * CGFloat(maxPageIndex+1)
    }

    public init(manager: ElegantListManager,
                pageTurnType: PageTurnType,
                bounces: Bool = false,
                viewForPage: @escaping (Int) -> AnyView) {
        self.manager = manager
        self.pageTurnType = pageTurnType
        self.bounces = bounces
        self.viewForPage = viewForPage
    }

    public var body: some View {
        ElegantListView(manager: self.manager,
                        listView: self.listView(),
                        isHorizontal: true,
                        pageTurnType: self.pageTurnType,
                        bounces: self.bounces)
    }

    private func listView() -> some View {
        HStack(alignment: .center, spacing: 0) {
            ElegantListController(manager: manager,
                                  axis: .horizontal,
                                  length: 300,
                                  pageTurnType: pageTurnType,
                                  viewForPage: viewForPage)
                .frame(width: pagerWidth)
        }
        .frame(width: screen.width, height: 100, alignment: .leading)
    }

}

extension ElegantHList {

    public func onPageChanged(_ callback: ((Int) -> Void)?) -> Self {
        manager.anyCancellable = manager.$currentPage
            .dropFirst()
            .filter { $0.state == .completed }
            .map { $0.index }
            .sink { page in
                callback?(page)
            }
        return self
    }

}
