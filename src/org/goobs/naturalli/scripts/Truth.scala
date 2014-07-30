package org.goobs.naturalli.scripts

import org.goobs.naturalli._
import org.goobs.naturalli.Messages._

import edu.stanford.nlp.util.logging.Redwood.Util._
import edu.stanford.nlp.util.Execution

/**
 * A command-line utility to check if a fact is true according to NaturalLI and the fact
 * database running on the server.
 * This requires a separate server running.
 *
 * @author gabor
 */
object Truth extends Client {

  def main(args:Array[String]):Unit = {
    Props.NATLOG_INDEXER_REPLNER = true  // before fillOptions to allow it to be overwritten
    Execution.fillOptions(classOf[Props], args)
    val weights = NatLog.hardNatlogWeights

    do {
      println("")
      val consequent:Fact = NatLog.annotate(io.StdIn.readLine("query> "), x => Utils.WORD_UNK).head
      explain(consequent, "query (consequent)")
      // We have our antecedent and consequent
      if (consequent.getWordCount > 0) {
        val query = Query.newBuilder()
          .setQueryFact(consequent)
          .setUseRealWorld(true)
          .setTimeout(100000)
          .setCosts(Learn.weightsToCosts(weights))
          .setSearchType("ucs")
          .setCacheType("bloom")
          .build()
        // Execute Query
        val paths:Iterable[Inference] = issueQuery(query)
        for (path <- paths) {
          log(recursivePrint(path))
        }
        // Evaluate Query
        import Implicits.flattenWeights
        val prob = probability(paths, weights)
        // Debug Print
        if (prob > 0.5) { println(Console.GREEN + "VALID" + Console.RESET + " (p=" + prob + ")") }
        else { println(Console.RED + "INVALID" + Console.RESET + " (p=" + prob + ")") }
      } else {
        err("No query provided!")
      }
    } while (true)
  }

}