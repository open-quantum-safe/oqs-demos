// Parses the output of OpenSSL propquery security_bits from oqs-provider, 
// and generates a sorted array of signatures/kems to be used by genconfig.py
object OsslAlgParser {
    import scala.annotation.tailrec

    val providerName = "oqsprovider"

    case class AlgSec(alg: String, seclevel: Int) {
        override def toString: String = s"('$alg', $seclevel)"
    }

    val defaultSigs = List(AlgSec("ecdsap256", 0), AlgSec("rsa3072", 0))

    @tailrec def readLines(line: String, in: List[AlgSec], seclevel: Option[Int]): List[AlgSec] = line match {
        case null => 
            in
        case l if l.contains("seclevel") =>
            val newSeclevel = Some(l.split(":")(1).toInt)
            readLines(scala.io.StdIn.readLine(), in, newSeclevel)
        case l =>
            val out = line.split(" @ ").map(_.trim) match {
                case i if i.length == 2 && i(1) == providerName => AlgSec(i(0), seclevel.get) :: in
                case _ => in
            }
            readLines(scala.io.StdIn.readLine(), out, seclevel)
    }

    def main(args: Array[String]): Unit = {
        if (args.length < 1) {
            println("Usage: <key_exchanges/signatures>")
            System.exit(0)
        }
        val kemsig = args(0)
        val schemes = readLines(scala.io.StdIn.readLine(), List[AlgSec](), None)
        val sorted = schemes.sortBy(i => {
            val spl = i.alg.split("_")
            (spl.length, spl.last, spl.head)
        })
        val fulllist = if (kemsig == "signatures") defaultSigs ++ sorted else sorted
        val schemeStr = s"$kemsig = [\n${fulllist.map(i => s"  $i").mkString(",\n")}\n]"
        println(schemeStr)
    }
}
