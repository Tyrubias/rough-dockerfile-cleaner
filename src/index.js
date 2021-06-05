import fs from 'fs'
import { DockerfileParser } from 'dockerfile-ast'

const dockerfilePath = process.argv[2]
const outputPath = process.argv[3]

try {
  const content = fs.readFileSync(dockerfilePath, 'utf8')
  const dockerfile = DockerfileParser.parse(content)
  const instructions = dockerfile.getInstructions()

  let isRunSequence = false
  let runCommand = ''

  for (const instruction of instructions) {
    if (instruction.getKeyword() === 'RUN') {
      if (isRunSequence) {
        runCommand += ' && '
      } else {
        isRunSequence = true
      }

      runCommand += instruction.getExpandedArguments().join(' ')
    } else {
      if (isRunSequence) {
        isRunSequence = false
        fs.writeFileSync(outputPath, 'RUN ' + runCommand + '\n', { flag: 'a+' })
        runCommand = ''
      }

      fs.writeFileSync(
        outputPath,
        instruction.getKeyword() +
          ' ' +
          instruction.getExpandedArguments().join(' ') +
          '\n',
        { flag: 'a+' }
      )
    }
  }
} catch (e) {
  console.log('Error: ', e.stack)
}
