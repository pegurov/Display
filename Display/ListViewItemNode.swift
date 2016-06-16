import Foundation
import AsyncDisplayKit

var testSpringFrictionLimits: (CGFloat, CGFloat) = (3.0, 60.0)
var testSpringFriction: CGFloat = 33.26

var testSpringConstantLimits: (CGFloat, CGFloat) = (3.0, 450.0)
var testSpringConstant: CGFloat = 450.0

var testSpringResistanceFreeLimits: (CGFloat, CGFloat) = (0.05, 1.0)
var testSpringFreeResistance: CGFloat = 1.0

var testSpringResistanceScrollingLimits: (CGFloat, CGFloat) = (0.1, 1.0)
var testSpringScrollingResistance: CGFloat = 0.4

struct ListViewItemSpring {
    let stiffness: CGFloat
    let damping: CGFloat
    let mass: CGFloat
    var velocity: CGFloat = 0.0
    
    init(stiffness: CGFloat, damping: CGFloat, mass: CGFloat) {
        self.stiffness = stiffness
        self.damping = damping
        self.mass = mass
    }
}

private class ListViewItemView: UIView {
    override class func layerClass() -> AnyClass {
        return ASTransformLayer.self
    }
}

public struct ListViewItemNodeLayout {
    public let contentSize: CGSize
    public let insets: UIEdgeInsets
    
    public init() {
        self.contentSize = CGSize()
        self.insets = UIEdgeInsets()
    }
    
    public init(contentSize: CGSize, insets: UIEdgeInsets) {
        self.contentSize = contentSize
        self.insets = insets
    }
    
    public var size: CGSize {
        return CGSize(width: self.contentSize.width + self.insets.left + self.insets.right, height: self.contentSize.height + self.insets.top + self.insets.bottom)
    }
}

public class ListViewItemNode: ASDisplayNode {
    final var index: Int?
    
    final var accessoryItemNode: ListViewAccessoryItemNode? {
        didSet {
            if let accessoryItemNode = self.accessoryItemNode {
                self.layoutAccessoryItemNode(accessoryItemNode)
            }
        }
    }
    
    final var accessoryHeaderItemNode: ListViewAccessoryItemNode?
    
    private final var spring: ListViewItemSpring?
    private final var animations: [(String, ListViewAnimation)] = []
    
    final let wantsScrollDynamics: Bool
    
    public final var scrollPositioningInsets: UIEdgeInsets = UIEdgeInsets()
    
    public final var insets: UIEdgeInsets = UIEdgeInsets() {
        didSet {
            let effectiveInsets = self.insets
            self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: self.contentSize.width, height: self.contentSize.height + effectiveInsets.top + effectiveInsets.bottom))
            self.bounds = CGRect(origin: CGPoint(x: 0.0, y: -effectiveInsets.top + self.contentOffset + self.transitionOffset), size: self.bounds.size)
            
            if oldValue != self.insets {
                if let accessoryItemNode = self.accessoryItemNode {
                    self.layoutAccessoryItemNode(accessoryItemNode)
                }
            }
        }
    }

    private final var _contentSize: CGSize = CGSize()
    public final var contentSize: CGSize {
        get {
            return self._contentSize
        } set(value) {
            let effectiveInsets = self.insets
            self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: value.width, height: value.height + effectiveInsets.top + effectiveInsets.bottom))
        }
    }
    
    private var contentOffset: CGFloat = 0.0 {
        didSet {
            let effectiveInsets = self.insets
            self.bounds = CGRect(origin: CGPoint(x: 0.0, y: -effectiveInsets.top + self.contentOffset + self.transitionOffset), size: self.bounds.size)
        }
    }
    
    public var transitionOffset: CGFloat = 0.0 {
        didSet {
            let effectiveInsets = self.insets
            self.bounds = CGRect(origin: CGPoint(x: 0.0, y: -effectiveInsets.top + self.contentOffset + self.transitionOffset), size: self.bounds.size)
        }
    }
    
    public var layout: ListViewItemNodeLayout {
        var insets = self.insets
        var contentSize = self.contentSize
        
        if let animation = self.animationForKey("insets") {
            insets = animation.to as! UIEdgeInsets
        }
        
        if let animation = self.animationForKey("apparentHeight") {
            contentSize.height = (animation.to as! CGFloat) - insets.top - insets.bottom
        }
        
        return ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
    }
    
    public init(layerBacked: Bool, dynamicBounce: Bool = true) {
        if true {
            if dynamicBounce {
                self.spring = ListViewItemSpring(stiffness: -280.0, damping: -24.0, mass: 0.85)
            }
            self.wantsScrollDynamics = dynamicBounce
        } else {
            self.wantsScrollDynamics = false
        }
        
        //super.init()
        
        //self.layerBacked = layerBacked
        
        if layerBacked {
            super.init(layerBlock: {
                return ASTransformLayer()
            }, didLoadBlock: nil)
        } else {
            super.init(viewBlock: {
                return ListViewItemView()
            }, didLoadBlock: nil)
        }
    }
    
    var apparentHeight: CGFloat = 0.0
    private var _bounds: CGRect = CGRect()
    private var _position: CGPoint = CGPoint()
    
    public override var frame: CGRect {
        get {
            return CGRect(origin: CGPoint(x: self._position.x - self._bounds.width / 2.0, y: self._position.y - self._bounds.height / 2.0), size: self._bounds.size)
        } set(value) {
            let previousSize = self._bounds.size
            
            super.frame = value
            self._bounds.size = value.size
            self._position = CGPoint(x: value.midX, y: value.midY)
            let effectiveInsets = self.insets
            self._contentSize = CGSize(width: value.size.width, height: value.size.height - effectiveInsets.top - effectiveInsets.bottom)
            
            if previousSize != value.size {
                if let accessoryItemNode = self.accessoryItemNode {
                    self.layoutAccessoryItemNode(accessoryItemNode)
                }
            }
        }
    }
    
    public override var bounds: CGRect {
        get {
            return self._bounds
        } set(value) {
            let previousSize = self._bounds.size
            
            super.bounds = value
            self._bounds = value
            let effectiveInsets = self.insets
            self._contentSize = CGSize(width: value.size.width, height: value.size.height - effectiveInsets.top - effectiveInsets.bottom)
            
            if previousSize != value.size {
                if let accessoryItemNode = self.accessoryItemNode {
                    self.layoutAccessoryItemNode(accessoryItemNode)
                }
            }
        }
    }
    
    public override var position: CGPoint {
        get {
            return self._position
        } set(value) {
            super.position = value
            self._position = value
        }
    }
    
    public final var apparentFrame: CGRect {
        var frame = self.frame
        frame.size.height = self.apparentHeight
        return frame
    }
    
    public final var apparentBounds: CGRect {
        var bounds = self.bounds
        bounds.size.height = self.apparentHeight
        return bounds
    }
    
    public func layoutAccessoryItemNode(accessoryItemNode: ListViewAccessoryItemNode) {
    }
    
    public func reuse() {
    }
    
    final func addScrollingOffset(scrollingOffset: CGFloat) {
        if self.spring != nil {
            self.contentOffset += scrollingOffset
        }
    }
    
    func initializeDynamicsFromSibling(itemView: ListViewItemNode, additionalOffset: CGFloat) {
        if let itemViewSpring = itemView.spring {
            self.contentOffset = itemView.contentOffset + additionalOffset
            self.spring?.velocity = itemViewSpring.velocity
        }
    }
    
    public func animate(timestamp: Double) -> Bool {
        var continueAnimations = false
        
        if let _ = self.spring {
            var offset = self.contentOffset
            
            let frictionConstant: CGFloat = testSpringFriction
            let springConstant: CGFloat = testSpringConstant
            let time: CGFloat = 1.0 / 60.0
            
            // friction force = velocity * friction constant
            let frictionForce = self.spring!.velocity * frictionConstant
            // spring force = (target point - current position) * spring constant
            let springForce = -self.contentOffset * springConstant
            // force = spring force - friction force
            let force = springForce - frictionForce
            
            // velocity = current velocity + force * time / mass
            self.spring!.velocity = self.spring!.velocity + force * time
            // position = current position + velocity * time
            offset = self.contentOffset + self.spring!.velocity * time
            
            offset = isnan(offset) ? 0.0 : offset
            
            let epsilon: CGFloat = 0.1
            if abs(offset) < epsilon && abs(self.spring!.velocity) < epsilon {
                offset = 0.0
                self.spring!.velocity = 0.0
            } else {
                continueAnimations = true
            }
            
            if abs(offset) > 250.0 {
                offset = offset < 0.0 ? -250.0 : 250.0
            }
            self.contentOffset = offset
        }
        
        var i = 0
        var animationCount = self.animations.count
        while i < animationCount {
            let (_, animation) = self.animations[i]
            animation.applyAt(timestamp)
            
            if animation.completeAt(timestamp) {
                animations.removeAtIndex(i)
                animationCount -= 1
                i -= 1
            } else {
                continueAnimations = true
            }
            
            i += 1
        }
        
        if let accessoryItemNode = self.accessoryItemNode {
            if (accessoryItemNode.animate(timestamp)) {
                continueAnimations = true
            }
        }
        
        return continueAnimations
    }
    
    public func layoutForWidth(width: CGFloat, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
    }
    
    public func animationForKey(key: String) -> ListViewAnimation? {
        for (animationKey, animation) in self.animations {
            if animationKey == key {
                return animation
            }
        }
        return nil
    }
    
    public final func setAnimationForKey(key: String, animation: ListViewAnimation?) {
        for i in 0 ..< self.animations.count {
            let (currentKey, currentAnimation) = self.animations[i]
            if currentKey == key {
                self.animations.removeAtIndex(i)
                currentAnimation.cancel()
                break
            }
        }
        if let animation = animation {
            self.animations.append((key, animation))
        }
    }
    
    public final func removeAllAnimations() {
        let previousAnimations = self.animations
        self.animations.removeAll()
        
        for (_, animation) in previousAnimations {
            animation.cancel()
        }
        
        self.accessoryItemNode?.removeAllAnimations()
    }
    
    public func addInsetsAnimationToValue(value: UIEdgeInsets, duration: Double, beginAt: Double) {
        let animation = ListViewAnimation(from: self.insets, to: value, duration: duration, curve: listViewAnimationCurveSystem, beginAt: beginAt, update: { [weak self] _, currentValue in
            if let strongSelf = self {
                strongSelf.insets = currentValue
            }
        })
        self.setAnimationForKey("insets", animation: animation)
    }
    
    public func addApparentHeightAnimation(value: CGFloat, duration: Double, beginAt: Double, update: ((CGFloat) -> Void)? = nil) {
        let animation = ListViewAnimation(from: self.apparentHeight, to: value, duration: duration, curve: listViewAnimationCurveSystem, beginAt: beginAt, update: { [weak self] progress, currentValue in
            if let strongSelf = self {
                strongSelf.apparentHeight = currentValue
                if let update = update {
                    update(progress)
                }
            }
        })
        self.setAnimationForKey("apparentHeight", animation: animation)
    }
    
    public func modifyApparentHeightAnimation(value: CGFloat, beginAt: Double) {
        if let previousAnimation = self.animationForKey("apparentHeight") {
            var duration = previousAnimation.startTime + previousAnimation.duration - beginAt
            if abs(self.apparentHeight - value) < CGFloat(FLT_EPSILON) {
                duration = 0.0
            }
            
            let animation = ListViewAnimation(from: self.apparentHeight, to: value, duration: duration, curve: listViewAnimationCurveSystem, beginAt: beginAt, update: { [weak self] _, currentValue in
                if let strongSelf = self {
                    strongSelf.apparentHeight = currentValue
                }
            })
            
            self.setAnimationForKey("apparentHeight", animation: animation)
        }
    }
    
    public func removeApparentHeightAnimation() {
        self.setAnimationForKey("apparentHeight", animation: nil)
    }
    
    public func addTransitionOffsetAnimation(value: CGFloat, duration: Double, beginAt: Double) {
        let animation = ListViewAnimation(from: self.transitionOffset, to: value, duration: duration, curve: listViewAnimationCurveSystem, beginAt: beginAt, update: { [weak self] _, currentValue in
            if let strongSelf = self {
                strongSelf.transitionOffset = currentValue
            }
        })
        self.setAnimationForKey("transitionOffset", animation: animation)
    }
    
    public func animateInsertion(currentTimestamp: Double, duration: Double) {
    }
    
    public func animateAdded(currentTimestamp: Double, duration: Double) {
    }
    
    public func setHighlighted(highlighted: Bool, animated: Bool) {
    }
    
    public func setupGestures() {
    }
    
    public func animateFrameTransition(progress: CGFloat) {
        
    }
}