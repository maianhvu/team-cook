import chalk from 'chalk'

export function requestMethodTag(method: string): string {
  switch (method) {
    case 'GET':
      return chalk.green('[GET]')
    case 'POST':
      return chalk.blue('[POST]')
    case 'PUT':
      return chalk.yellow('[PUT]')
    case 'DELETE':
      return chalk.red('[DELETE]')
    case 'PATCH':
      return chalk.magenta('[PATCH]')
    default:
      return chalk.white(`[${method.toUpperCase()}]`)
  }
}
