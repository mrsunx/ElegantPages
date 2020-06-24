// Kevin Li - 6:14 PM - 6/23/20

import SwiftUI

private class UpdateUIViewControllerBugFixClass { }

struct ElegantListView: UIViewControllerRepresentable, ElegantListManagerDirectAccess {

    typealias UIViewControllerType = ElegantPagerController

    // See https://stackoverflow.com/questions/58635048/in-a-uiviewcontrollerrepresentable-how-can-i-pass-an-observedobjects-value-to
    private let bugFix = UpdateUIViewControllerBugFixClass()

    @ObservedObject var pagerManager: ElegantListManager

    let axis: Axis

    func makeUIViewController(context: Context) -> ElegantPagerController {
        ElegantPagerController(manager: pagerManager, axis: axis)
    }

    func updateUIViewController(_ controller: ElegantPagerController, context: Context) {
        DispatchQueue.main.async {
            self.setProperPage(for: controller)
        }
        pagerManager.delegate?.willDisplay(page: currentPage.index)
    }

    private func setProperPage(for controller: ElegantPagerController) {
        switch currentPage.state {
        case .rearrange:
            controller.rearrange(manager: pagerManager) {
                self.setActiveIndex(1, animated: false, complete: true) // resets to center
            }
        case .scroll:
            let pageToTurnTo = currentPage.index > controller.previousPage ? maxPageIndex : 0

            if currentPage.index == 0 || currentPage.index == pageCount-1 {
                setActiveIndex(pageToTurnTo, animated: true, complete: true)
                controller.reset(manager: pagerManager)
            } else {
                // This first call to `setActiveIndex` is responsible for animating the page
                // turn to whatever page we want to scroll to
                setActiveIndex(pageToTurnTo, animated: true, complete: false)
                controller.reset(manager: pagerManager) {
                    self.setActiveIndex(1, animated: false, complete: true)
                }
            }
        case .completed:
            ()
        }
    }

    private func setActiveIndex(_ index: Int, animated: Bool, complete: Bool) {
        withAnimation(animated ? pageTurnAnimation : nil) {
            self.pagerManager.activeIndex = index
        }

        if complete {
            pagerManager.currentPage.state = .completed
        }
    }

}

class ElegantPagerController: UIViewController {

    private var controllers: [UIHostingController<AnyView>]
    private(set) var previousPage: Int

    let axis: Axis

    init(manager: ElegantListManager, axis: Axis) {
        self.axis = axis
        previousPage = manager.currentPage.index

        controllers = manager.pageRange.map { page in
            UIHostingController(rootView: manager.datasource.view(for: page))
        }
        super.init(nibName: nil, bundle: nil)

        controllers.enumerated().forEach { i, controller in
            addChild(controller)

            if axis == .horizontal {
                controller.view.frame = CGRect(x: screen.width * CGFloat(i),
                                               y: 0,
                                               width: screen.width,
                                               height: screen.height)
            } else {
                controller.view.frame = CGRect(x: 0,
                                               y: screen.height * CGFloat(i),
                                               width: screen.width,
                                               height: screen.height)
            }

            view.addSubview(controller.view)
            controller.didMove(toParent: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func rearrange(manager: ElegantListManager, completion: @escaping () -> Void) {
        defer {
            previousPage = manager.currentPage.index
        }

        // rearrange if...
        guard manager.currentPage.index != previousPage && // not same page
            (previousPage != 0 &&
                manager.currentPage.index != 0) && // not 1st or 2nd page
            (previousPage != manager.pageCount-1 &&
                manager.currentPage.index != manager.pageCount-1) // not last page or 2nd to last page
        else { return }

        rearrangeControllersAndUpdatePage(manager: manager)
        resetPagePositions()
        completion()
    }

    private func rearrangeControllersAndUpdatePage(manager: ElegantListManager) {
        if manager.currentPage.index > previousPage { // scrolled down
            controllers.append(controllers.removeFirst())
            controllers.last!.rootView = manager.datasource.view(for: manager.currentPage.index+1)
        } else { // scrolled up
            controllers.insert(controllers.removeLast(), at: 0)
            controllers.first!.rootView = manager.datasource.view(for: manager.currentPage.index-1)
        }
    }

    private func resetPagePositions() {
        controllers.enumerated().forEach { i, controller in
            if axis == .horizontal {
                controller.view.frame.origin = CGPoint(x: screen.width * CGFloat(i), y: 0)
            } else {
                controller.view.frame.origin = CGPoint(x: 0, y: screen.height * CGFloat(i))
            }
        }
    }

    func reset(manager: ElegantListManager, completion: (() -> Void)? = nil) {
        defer {
            previousPage = manager.currentPage.index
        }

        zip(controllers, manager.pageRange).forEach { controller, page in
            controller.rootView = manager.datasource.view(for: page)
        }

        completion?()
    }

}

private extension ElegantListManager {

    var pageRange: ClosedRange<Int> {
        let startingPage: Int

        if currentPage.index == pageCount-1 {
            startingPage = (pageCount-3).clamped(to: 0...pageCount-1)
        } else {
            startingPage = (currentPage.index-1).clamped(to: 0...pageCount-1)
        }

        let trailingPage = (startingPage+2).clamped(to: 0...pageCount-1)

        return startingPage...trailingPage
    }

}