//
//  PropertyListDataSource.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 19..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
import CMIOKit

struct PropertyListItem {
    var property: Property
    var name: String
    var isSettable: Bool
    var value: String
    var fourCC: UInt32?
}

class PropertyListDataSource {
    private(set) var items: [PropertyListItem] = []
    
    func reload(forNode node: CMIONode<Properties>?, scope: CMIOObjectPropertyScope) {
        items.removeAll()
        
        guard let node = node else {
            return
        }
        
        struct ObjectID: Property {
            let selector: CMIOObjectPropertySelector = kCMIOObjectPropertySelectorWildcard
            let type: PropertyType = .objectID
            let readSemantics: PropertyReadSemantics = .read
        }
        
        items.append(PropertyListItem(property: ObjectID(),
                                      name: "objectID",
                                      isSettable: false,
                                      value: "@\(node.objectID)",
                                      fourCC: nil))

        items.append(contentsOf: properties(from: ObjectProperty.self, scope: scope, in: node.objectID))

        if node.properties.classID.isSubclass(of: .device) {
            items.append(contentsOf: properties(from: DeviceProperty.self, scope: scope, in: node.objectID))
        }
        else if node.properties.classID.isSubclass(of: .stream) {
            items.append(contentsOf: properties(from: StreamProperty.self, scope: scope, in: node.objectID))
        }
        else if node.properties.classID.isSubclass(of: .control) {
            items.append(contentsOf: properties(from: ControlProperty.self, scope: scope, in: node.objectID))
            
            if node.properties.classID.isSubclass(of: .booleanControl) {
                items.append(contentsOf: properties(from: BooleanControlProperty.self, scope: scope, in: node.objectID))
            }
            else if node.properties.classID.isSubclass(of: .selectorControl) {
                items.append(contentsOf: properties(from: SelectorControlProperty.self, scope: scope, in: node.objectID))
            }
            else if node.properties.classID.isSubclass(of: .featureControl) {
                items.append(contentsOf: properties(from: FeatureControlProperty.self, scope: scope, in: node.objectID))
                
                if node.properties.classID.isSubclass(of: .exposureControl) {
                    items.append(contentsOf: properties(from: ExposureControlProperty.self, scope: scope, in: node.objectID))
                }
            }
        }
        else if node.properties.classID == .system {
            items.append(contentsOf: properties(from: SystemProperty.self, scope: scope, in: node.objectID))
        }
    }
    
    private func properties<S>(from type: S.Type,
                               scope: CMIOObjectPropertyScope,
                               in objectID: CMIOObjectID) -> [PropertyListItem] where S: PropertySet {
        var propertyList: [PropertyListItem] = []
        let props = S.allExisting(scope: scope,
                                  element: .anyElement,
                                  in: objectID)
        for prop in props {
            var fourCC: UInt32?
            switch prop.type {
            case .classID, .fourCC, .propertyScope, .propertyElement:
                let value = prop.value(scope: scope, in: objectID)
                switch value {
                case .classID(let v), .fourCC(let v), .propertyScope(let v), .propertyElement(let v): fourCC = v
                default: break
                }
            default: break
            }
            let item = PropertyListItem(property: prop,
                                        name: "\(prop)",
                                        isSettable: prop.isSettable(scope: scope, in: objectID),
                                        value: prop.description(scope: scope, in: objectID) ?? "#ERROR",
                                        fourCC: fourCC)
            propertyList.append(item)
        }
        return propertyList
    }
    
}
