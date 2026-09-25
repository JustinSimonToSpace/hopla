import Foundation
import Testing
@testable import Hopla

@Suite(.serialized) struct RoutesTests {
    init() {
        let s = Settings.shared
        s.excludedExercises = []
        s.seatedOnly = false
        s.variation = .perVisit
        s.sessionSeconds = 60
    }

    @Test func everyDurationHasTenCompleteRoutes() {
        let expectedSteps = [30: 2, 45: 3, 60: 4, 120: 6]
        for duration in RouteBook.durations {
            let routes = RouteBook.routes[duration] ?? []
            #expect(routes.count == RouteBook.routesPerDuration)
            for route in routes {
                #expect(route.count == expectedSteps[duration])
                #expect(route.allSatisfy { Exercise.find($0) != nil }, "unknown exercise in \(route)")
                #expect(Set(route).count == route.count, "duplicate exercise in \(route)")
                #expect(Exercise.find(route[0])?.posture == .seated, "a route starts seated at the desk")
                #expect(Exercise.find(route.last!)?.posture == .standing, "a route ends standing")
            }
        }
    }

    @Test func stepLengthMatchesTheSessionLength() {
        for duration in RouteBook.durations {
            let steps = RouteBook.session(route: 0, seconds: duration)
            let total = steps.reduce(0) { $0 + $1.seconds }
            #expect(Int(total) == duration)
        }
    }

    @Test func excludedExercisesAreReplacedBySimilarOnes() {
        Settings.shared.excludedExercises = ["neck", "march"]
        for index in 0..<RouteBook.routesPerDuration {
            let original = RouteBook.routes[60]![index].compactMap(Exercise.find)
            let steps = RouteBook.session(route: index, seconds: 60).map(\.exercise)
            #expect(steps.count == original.count)
            #expect(!steps.contains { ["neck", "march"].contains($0.id) })
            #expect(Set(steps.map(\.id)).count == steps.count, "no exercise twice in a session")
            for (wanted, got) in zip(original, steps) { #expect(wanted.posture == got.posture) }
        }
    }

    @Test func seatedOnlyNeverAsksToStand() {
        Settings.shared.seatedOnly = true
        for duration in RouteBook.durations {
            for index in 0..<RouteBook.routesPerDuration {
                #expect(RouteBook.session(route: index, seconds: duration).allSatisfy { $0.exercise.posture == .seated })
            }
        }
    }

    @Test func excludingNearlyEverythingStillGivesASession() {
        Settings.shared.excludedExercises = Set(Exercise.all.map(\.id).dropFirst())
        let steps = RouteBook.session(route: 3, seconds: 120)
        #expect(steps.count == 6)
    }

    @Test func perVisitRotationNeverRepeatsBeforeAllRoutesWereDone() {
        let day = Date()
        var seen: [Int] = []
        for _ in 0..<RouteBook.routesPerDuration {
            seen.append(RouteBook.currentIndex(now: day))
            _ = RouteBook.nextSession(now: day)
        }
        #expect(Set(seen).count == RouteBook.routesPerDuration)
    }

    @Test func pinnedRouteIsUsedWhenVariationIsNever() {
        Settings.shared.variation = .never
        Settings.shared.pinnedRoute = 7
        #expect(RouteBook.currentIndex() == 7)
        Settings.shared.variation = .perVisit
    }
}
