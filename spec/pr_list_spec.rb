require "spec_helper"
require "pr_list"

module PRlist
  describe "PRlist" do
    let (:repo) { "foobar/baz-bat" }
    let (:repo_short) { "baz-bat" }

    it "has a VERSION" do
      expect(VERSION).not_to be nil
    end

    it "has an IDENT" do
      expect(IDENT).not_to be nil
    end

    describe OptParse do
      let (:options) { OptParse.parse([], true) }

      context "#label_values" do
        it "should be valid" do
          expect(OptParse).to respond_to(:label_values)
        end

        it "should return a flattened Array" do
          allow(options).to receive(:labels) { { one: 1, two: [2, 3], three: nil, four: 4 } }
          expect(OptParse.label_values).to be_an(Array)
          expect(OptParse.label_values).to eq([1, 2, 3, 4])
        end
      end

      context "--queue" do
        it "should be valid" do
          my_options = nil

          expect { my_options = OptParse.parse(%w(--queue), true) }.not_to raise_error
          expect(my_options.queue).to be true # can be set
        end

        it "should be negatable" do
          my_options = nil

          expect { my_options = OptParse.parse(%w(--no-queue), true) }.not_to raise_error
          expect(my_options.queue).to be false # can be unset
        end

        it "should default to false" do
          expect(options.queue).to be false
        end
      end

      context "--markdown" do
        it "should be valid" do
          my_options = nil

          expect { my_options = OptParse.parse(%w(--markdown), true) }.not_to raise_error
          expect(my_options.markdown).to be true # can be set
        end
      end

    end

    describe PullRequest do
      let (:issue) { build(:issue) }
      let (:pull_request) { PullRequest.new issue }

      it "should have a valid date method" do
        expect(pull_request).to respond_to(:date)
        expect(pull_request.date).not_to be nil
        expect(pull_request.date).to eq(issue.created_at)
      end

      it "should have a valid labels method" do
        expect(pull_request).to respond_to(:labels)
        expect(pull_request.labels).not_to be nil
        expect(pull_request.labels).to be_an(Array)
      end

      context "should defer to issue methods" do
        it "#pull_request?" do
          expect(pull_request).to respond_to(:pull_request?)
          expect(pull_request.pull_request?).to be true
        end

        it "#number" do
          expect(pull_request).to respond_to(:number)
          expect(pull_request.number).to eq(issue.number)
        end

        it "#title" do
          expect(pull_request).to respond_to(:title)
          expect(pull_request.title).to eq(issue.title)
        end
      end

      context "#has_label?" do
        it "should be valid" do
          expect(pull_request).to respond_to(:has_label?)
        end

        it "should accept and match a String" do
          expect(pull_request.has_label?("Please Review")).to be true
        end

        it "should accept and match an Array" do
          expect(pull_request.has_label?(["Please Review"])).to be true
        end

        it "should accept match multiple values and mixed case" do
          expect(pull_request.has_label?(["foo", "bar", "PLEASE REVIEW ", "baz"])).to be true
        end
      end

      context "#repo" do
        it "should return the full repository name by default" do
          expect(pull_request.repo).to eq(repo)
        end

        it "should return the short repository name when requested" do
          expect(pull_request.repo(short: true)).to eq(repo_short)
        end
      end
    end

    describe PullRequests do
      let (:pull_requests) { PullRequests.new 123456789 }
      let (:issue1) { build(:issue, :created_at => "2016-01-01 18:00:00.000000000 Z") }
      let (:issue2) { build(:issue, :created_at => "2016-01-01 17:59:00.000000000 Z") }
      let (:github) { build(:github, :issues => [issue1, issue2]) }

      before (:each) do
        allow(Octokit::Client).to receive(:new) { github }
        allow(github).to receive(:issues) { [issue1, issue2] }
      end

      context "#auth!" do
        it "should (re-)authenticate" do
          pull_requests.auth!("foobarbazbat")

          expect(Octokit::Client).to have_received(:new).with(hash_including(:access_token => "foobarbazbat"))
        end
      end

      context "#authorized?" do
        it "should respond true when authorized" do
          expect(pull_requests.authorized?).to be true
        end

        it "should respond false when not authorized" do
          allow(Octokit::Client).to receive(:new) { nil }
          expect(pull_requests.authorized?).to be false
        end
      end

      context "#load!" do
        it "should be valid" do
          expect(pull_requests).to respond_to(:load!)
        end

        it "should load issues" do
          pull_requests.load!(repo)
          expect(github).to have_received(:issues)
          expect(pull_requests.pulls.length).to eq(2)
        end
      end

      context "#by_date" do
        before(:each) do
          pull_requests.load!(repo)
        end

        it "should return an Array" do
          expect(pull_requests.by_date).to be_an(Array)
        end

        it "should return issues ordered by created_at" do
          pr = pull_requests.by_date
          expect(pr.length).to eq(2)
          expect(pr[0].issue).to eql(issue2)
          expect(pr[1].issue).to eql(issue1)
        end
      end

      context "#repos" do
        it "should return repository name(s)" do
          pull_requests.load!(repo)
          expect(pull_requests.repos).to eq([repo])
        end
      end

    end
  end
end

