"""Tests for tree building service."""

import pytest
from trial_balance_extractor.models.schemas import TrialBalanceItem, TreeNode
from trial_balance_extractor.services.tree_builder import TreeBuilder


class TestTreeBuilder:
    """Test cases for TreeBuilder service."""
    
    def setup_method(self):
        """Setup test instance."""
        self.tree_builder = TreeBuilder()
    
    def test_build_tree_from_items(self):
        """Test building tree from TrialBalanceItem objects."""
        items = [
            TrialBalanceItem(
                account_code="100",
                account_name="KASA",
                debit=1000.0,
                credit=500.0,
                debit_balance=500.0,
                credit_balance=0.0,
                parent_account_code=None,
                account_number=1,
                period_id=1
            ),
            TrialBalanceItem(
                account_code="100.01",
                account_name="TL KASA", 
                debit=600.0,
                credit=200.0,
                debit_balance=400.0,
                credit_balance=0.0,
                parent_account_code="100",
                account_number=1,
                period_id=1
            ),
            TrialBalanceItem(
                account_code="120",
                account_name="BANKALAR",
                debit=5000.0,
                credit=1000.0,
                debit_balance=4000.0,
                credit_balance=0.0,
                parent_account_code=None,
                account_number=1,
                period_id=1
            )
        ]
        
        tree = self.tree_builder.build_tree_from_items(items)
        
        # Should have 2 root nodes
        assert len(tree) == 2
        
        # Find KASA root node
        kasa_node = next((node for node in tree if node.account_code == "100"), None)
        assert kasa_node is not None
        assert kasa_node.account_name == "KASA"
        assert len(kasa_node.children) == 1
        
        # Check child node
        child = kasa_node.children[0]
        assert child.account_code == "100.01"
        assert child.account_name == "TL KASA"
    
    def test_build_tree_from_dict(self):
        """Test building tree from dictionary data."""
        data = [
            {
                "AccountCode": "100",
                "AccountName": "KASA",
                "Debit": 1000.0,
                "Credit": 500.0,
                "DebitBalance": 500.0,
                "CreditBalance": 0.0,
                "ParentAccountCode": None
            },
            {
                "AccountCode": "100.01", 
                "AccountName": "TL KASA",
                "Debit": 600.0,
                "Credit": 200.0,
                "DebitBalance": 400.0,
                "CreditBalance": 0.0,
                "ParentAccountCode": "100"
            }
        ]
        
        tree = self.tree_builder.build_tree_from_dict(data)
        
        # Should have 1 root node
        assert len(tree) == 1
        
        root = tree[0]
        assert root.account_code == "100"
        assert len(root.children) == 1
        assert root.children[0].account_code == "100.01"
    
    def test_flatten_tree(self):
        """Test flattening tree structure."""
        # Create a simple tree
        root = TreeNode(
            account_code="100",
            account_name="KASA",
            debit=1000.0,
            credit=500.0,
            debit_balance=500.0,
            credit_balance=0.0,
            parent_account_code=None,
            children=[
                TreeNode(
                    account_code="100.01",
                    account_name="TL KASA",
                    debit=600.0,
                    credit=200.0,
                    debit_balance=400.0,
                    credit_balance=0.0,
                    parent_account_code="100",
                    children=[]
                )
            ]
        )
        
        items = self.tree_builder.flatten_tree([root])
        
        # Should have 2 items
        assert len(items) == 2
        
        # Check root item
        root_item = next((item for item in items if item.account_code == "100"), None)
        assert root_item is not None
        assert root_item.account_name == "KASA"
        
        # Check child item
        child_item = next((item for item in items if item.account_code == "100.01"), None)
        assert child_item is not None
        assert child_item.account_name == "TL KASA"
    
    def test_calculate_hierarchy_levels(self):
        """Test hierarchy level calculation."""
        root = TreeNode(
            account_code="100",
            account_name="KASA",
            debit=0.0,
            credit=0.0,
            debit_balance=0.0,
            credit_balance=0.0,
            parent_account_code=None,
            children=[
                TreeNode(
                    account_code="100.01",
                    account_name="TL KASA",
                    debit=0.0,
                    credit=0.0,
                    debit_balance=0.0,
                    credit_balance=0.0,
                    parent_account_code="100",
                    children=[
                        TreeNode(
                            account_code="100.01.001",
                            account_name="KASA 1",
                            debit=0.0,
                            credit=0.0,
                            debit_balance=0.0,
                            credit_balance=0.0,
                            parent_account_code="100.01",
                            children=[]
                        )
                    ]
                )
            ]
        )
        
        levels = self.tree_builder.calculate_hierarchy_levels([root])
        
        assert levels["100"] == 0
        assert levels["100.01"] == 1
        assert levels["100.01.001"] == 2
    
    def test_get_tree_statistics(self):
        """Test tree statistics calculation."""
        root = TreeNode(
            account_code="100",
            account_name="KASA",
            debit=0.0,
            credit=0.0,
            debit_balance=0.0,
            credit_balance=0.0,
            parent_account_code=None,
            children=[
                TreeNode(
                    account_code="100.01",
                    account_name="TL KASA",
                    debit=0.0,
                    credit=0.0,
                    debit_balance=0.0,
                    credit_balance=0.0,
                    parent_account_code="100",
                    children=[]
                ),
                TreeNode(
                    account_code="100.02",
                    account_name="USD KASA",
                    debit=0.0,
                    credit=0.0,
                    debit_balance=0.0,
                    credit_balance=0.0,
                    parent_account_code="100",
                    children=[]
                )
            ]
        )
        
        stats = self.tree_builder.get_tree_statistics([root])
        
        assert stats["total_nodes"] == 3
        assert stats["root_nodes"] == 1
        assert stats["leaf_nodes"] == 2
        assert stats["max_depth"] == 1
        assert stats["internal_nodes"] == 1
    
    def test_empty_data(self):
        """Test handling of empty data."""
        # Empty items list
        tree = self.tree_builder.build_tree_from_items([])
        assert tree == []
        
        # Empty dictionary list
        tree = self.tree_builder.build_tree_from_dict([])
        assert tree == []
        
        # Empty tree for flattening
        items = self.tree_builder.flatten_tree([])
        assert items == []


if __name__ == "__main__":
    pytest.main([__file__])
