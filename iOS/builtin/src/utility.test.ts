import { isNotEmptyString, isOfType } from "./utility"

test('isNotEmptyString("") return false', () => {
    expect(isNotEmptyString('')).toBe(false)
})

test('isNotEmptyString() pass not empty string return true', () => {
    expect(isNotEmptyString('content')).toBe(true)
})

test('isNotEmptyString() pass primitive value return false', () => {
    expect(isNotEmptyString(0)).toBe(false)
    expect(isNotEmptyString(true)).toBe(false)
    expect(isNotEmptyString(Symbol())).toBe(false)
    expect(isNotEmptyString({})).toBe(false)
    expect(isNotEmptyString(undefined)).toBe(false)
    expect(isNotEmptyString(null)).toBe(false)
})

test('isOfType pass undefined return false', () => {
    class TestA { fakeMethod() { return 123 } }
    expect(isOfType<TestA>(undefined, 'fakeMethod')).toBe(false)
})