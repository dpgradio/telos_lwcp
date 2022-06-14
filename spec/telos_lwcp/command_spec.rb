require 'spec_helper'

describe TelosLWCP::Command do
  describe "#new" do
    context "simple initial server response" do
      subject { TelosLWCP::Command.incoming('indi cc server_id="VX Engine", server_version="1.1.4", server_caps="brhi", lwcp_version=1, zone=EU, uid="5850AB402297", online=TRUE')}
      it("parses the command") { expect(subject.command).to eq 'indi' }
      it("parses the object" ) { expect(subject.object).to eq 'cc' }
      it("handles strings in arguments") { expect(subject.arguments[:server_id]).to eq 'VX Engine'}
      it("handles integers in arguments") { expect(subject.arguments[:lwcp_version]).to eq 1}
      it("handles booleans in arguments") { expect(subject.arguments[:online]).to eq true }
      it("handles constants in arguments") { expect(subject.arguments[:zone]).to eq :EU}
    end

    context "server response with extra data" do
      subject { TelosLWCP::Command.incoming('ack studio $status=ERR $msg="User is not logged in."') }

      it("parses constants in system items") { expect(subject.system_items[:status]).to eq :ERR }
      it("parses strings in system items") { expect(subject.system_items[:msg]).to eq "User is not logged in." }
    end

    context "server response with arrays" do
      subject { TelosLWCP::Command.incoming('event studio id=1, name="Studio 1", show_id=1, show_name="Show 1", next=0, pnext=0, busy_all=FALSE, num_lines=12, num_hybrids=8, num_hyb_fixed=4, mute=FALSE, show_locked=FALSE, auto_answer=FALSE, line_list=[[IDLE, IDLE, "Main-Studio", "10", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "Main-Studio", "10", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "Main-Studio", "10", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "Line 20", "20", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "67-614-448", "67614448", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "67-614-449", "67614449", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "Cisco 40", "40", NULL, 0, NULL, "", NONE], [IDLE, IDLE, "Cisco 80", "80", NULL, 0, NULL, "", NONE], NULL, [IDLE, IDLE, "VIP", "88", NULL, 1, NULL, "", NONE], [IDLE, IDLE, "NEWS", "89", NULL, 2, NULL, "", NONE], [IDLE, IDLE, "HOT-LINE", "90", NULL, 3, NULL, "", NONE]]') }

      it { expect(subject.arguments[:line_list]).to be_an_instance_of Array }
      it { expect(subject.arguments[:line_list].size).to eq 12 }
    end

    context "server response with incoming call" do
      subject { TelosLWCP::Command.incoming("event studio id=11, name=\"Virtuele studio L3\", show_id=6, show_name=\"Virtuele studio L3\", next=1, pnext=1, busy_all=FALSE, num_lines=6, num_hybrids=6, num_hyb_fixed=0, mute=FALSE, show_locked=FALSE, auto_answer=FALSE, line_list=[[RINGING_IN, RINGING_IN, \"Vstu 3 L1\", \"sip:4331@dpgmediaradio.3cx.be\", \"sip:32484326161@127.0.0.1:5060;nf=e\", 0, 1, \"\", INCOMING], [IDLE, IDLE, \"Vstu 3 L2\", \"sip:4332@dpgmediaradio.3cx.be\", NULL, 0, NULL, \"\", NONE], [IDLE, IDLE, \"Vstu 3 L3\", \"sip:4333@dpgmediaradio.3cx.be\", NULL, 0, NULL, \"\", NONE], [IDLE, IDLE, \"Vstu 3 L4\", \"sip:4334@dpgmediaradio.3cx.be\", NULL, 0, NULL, \"\", NONE], [IDLE, IDLE, \"Vstu 3 L5\", \"sip:4335@dpgmediaradio.3cx.be\", NULL, 0, NULL, \"\", NONE], [IDLE, IDLE, \"Vstu 3 L6\", \"sip:4336@dpgmediaradio.3cx.be\", NULL, 0, NULL, \"\", NONE]]") }

      it { expect(subject.arguments[:line_list]).to be_an_instance_of Array }
      it { expect(subject.arguments[:line_list].size).to eq 6 }
      it { expect(subject.arguments[:line_list][0][4]).to eq 'sip:32484326161@127.0.0.1:5060;nf=e' }
    end
  end
end