//
//  WhereClause.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

struct WhereClause {
    let condition: String
}

private func makeWhere<Model: Queryable, VP, V: QueryValue>(
    _ keyPath: KeyPath<Model, VP>,
    op: String,
    _ value: V
) -> WhereClause {
    guard let key = Model.fieldName(for: keyPath) else {
        return WhereClause(condition: "")
    }
    return WhereClause(condition: "\(key) \(op) \(value.queryString)")
}

func == <M: Queryable, VP, V: QueryValue>(
    lhs: KeyPath<M, VP>,
    rhs: V
) -> WhereClause {
    return makeWhere(lhs, op: "=", rhs)
}

func != <M: Queryable, VP, V: QueryValue>(
    lhs: KeyPath<M, VP>,
    rhs: V
) -> WhereClause {
    return makeWhere(lhs, op: "!=", rhs)
}

func > <M: Queryable, VP, V: QueryValue>(
    lhs: KeyPath<M, VP>,
    rhs: V
) -> WhereClause {
    return makeWhere(lhs, op: ">", rhs)
}

func < <M: Queryable, VP, V: QueryValue>(
    lhs: KeyPath<M, VP>,
    rhs: V
) -> WhereClause {
    return makeWhere(lhs, op: "<", rhs)
}

func >= <M: Queryable, VP, V: QueryValue>(
    lhs: KeyPath<M, VP>,
    rhs: V
) -> WhereClause {
    return makeWhere(lhs, op: ">=", rhs)
}

func <= <M: Queryable, VP, V: QueryValue>(
    lhs: KeyPath<M, VP>,
    rhs: V
) -> WhereClause {
    return makeWhere(lhs, op: "<=", rhs)
}

func && (left: WhereClause, right: WhereClause) -> WhereClause {
    return WhereClause(condition: "(\(left.condition) & \(right.condition))")
}

func || (left: WhereClause, right: WhereClause) -> WhereClause {
    return WhereClause(condition: "(\(left.condition) | \(right.condition))")
}
