public extension NavigationRouter {
    /// 直接切换根层命名栈；nil 保持选择，事务协调仍由 submit 负责。
    @discardableResult
    func selectScope(_ scope: Scope?) -> NavigationMutationResult {
        guard let scope else { return recordMutation(.noChange(.noSelection), operation: "selectScope") }
        let stack = NavigationStackID.scope(scope)
        guard rootLayer.route.destination.providesNavigationContainer else {
            return recordMutation(.rejected(.incompatibleContainer), operation: "selectScope", stack: stack)
        }
        guard rootLayer.stacks[stack] != nil else {
            return recordMutation(.rejected(.undeclaredStack), operation: "selectScope", stack: stack)
        }
        rootLayer.selectedStack = stack
        return recordMutation(.applied, operation: "selectScope", stack: stack)
    }

    /// 原子替换根层的命名栈路径；任何未声明的栈都会使整批操作被拒绝。
    @discardableResult
    func setPaths(_ paths: [Scope: [Destination]]) -> NavigationMutationResult {
        guard rootLayer.route.destination.providesNavigationContainer else {
            return recordMutation(.rejected(.incompatibleContainer), operation: "setPaths")
        }
        guard paths.keys.allSatisfy({ rootLayer.stacks[.scope($0)] != nil }) else {
            return recordMutation(.rejected(.undeclaredStack), operation: "setPaths")
        }
        rootLayer.paths = Dictionary(uniqueKeysWithValues: paths.map { (.scope($0.key), $0.value) })
        return recordMutation(.applied, operation: "setPaths")
    }

    /// 声明或替换 App 根层指定命名栈的栈底页面，并清空该栈的 push 路径。
    /// 不切换选中的栈；空详情使用明确的空态 Destination。
    @discardableResult
    func setRootDestination(_ destination: Destination, for scope: Scope) -> NavigationMutationResult {
        guard rootLayer.route.destination.providesNavigationContainer else {
            return recordMutation(
                .rejected(.incompatibleContainer),
                operation: "setRootDestination",
                stack: .scope(scope)
            )
        }
        rootLayer.setRoot(destination, for: .scope(scope))
        return recordMutation(.applied, operation: "setRootDestination", stack: .scope(scope))
    }

    /// 替换 App 根层指定命名栈的 push 路径，保留栈底页面、选中的栈和模态。
    @discardableResult
    func setPath(_ path: [Destination], for scope: Scope) -> NavigationMutationResult {
        let stack = NavigationStackID.scope(scope)
        guard rootLayer.route.destination.providesNavigationContainer else {
            return recordMutation(.rejected(.incompatibleContainer), operation: "setPath", stack: stack)
        }
        guard let state = rootLayer.stacks[stack] else {
            return recordMutation(.rejected(.undeclaredStack), operation: "setPath", stack: stack)
        }
        state.path = path
        return recordMutation(.applied, operation: "setPath", stack: stack)
    }

    /// 选中 App 根层的指定命名栈，再 push 一个页面；省略 scope 时在根层当前选中的栈中 push。
    /// 当前选中的是 primary 栈时也可省略 scope，不要求根界面使用 TabView。
    /// 此方法会保留已经打开的模态。需要先确认并关闭模态时，向 submit 提交 .push 请求。
    @discardableResult
    func push(_ destination: Destination, on scope: Scope? = nil) -> NavigationMutationResult {
        let targetStack = scope.map(NavigationStackID.scope) ?? rootLayer.selectedStack
        guard rootLayer.route.destination.providesNavigationContainer || targetStack == .primary else {
            return recordMutation(.rejected(.incompatibleContainer), operation: "push", stack: targetStack)
        }
        guard let state = rootLayer.stacks[targetStack] else {
            return recordMutation(.rejected(.undeclaredStack), operation: "push", stack: targetStack)
        }
        rootLayer.selectedStack = targetStack
        state.path.append(destination)
        return recordMutation(.applied, operation: "push", stack: targetStack)
    }

    private func recordMutation(
        _ result: NavigationMutationResult, operation: String, stack: NavigationStackID<Scope>? = nil
    ) -> NavigationMutationResult {
        NavigationCoreLog.record(
            result,
            operation: operation,
            layer: .root,
            stack: stack.map { String(describing: $0) }
        )
    }
}
