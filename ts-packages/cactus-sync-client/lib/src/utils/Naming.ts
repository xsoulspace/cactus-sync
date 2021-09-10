export const toPluralName = (str: string) => {
  const lastLetter = str.substr(str.length - 1).toLowerCase()
  let newStr = str.toString()
  switch (lastLetter) {
    case 'h':
      newStr = `${newStr}es`
      return newStr
    case 'y':
      newStr = newStr.substr(0, newStr.length - 1)
      newStr = `${newStr}ies`
      return newStr

    default:
      return `${str}s`
  }
}
